import test from 'node:test';
import assert from 'node:assert/strict';
import { manageAdmin, parseArguments } from '../scripts/manage-admin.mjs';

test('admin provisioning CLI defaults to dry run and rejects ambiguous or unsafe targets', () => {
  assert.deepEqual(parseArguments(['--grant', '--uid', 'alice']), {
    project: 'vetalife-24f03', uid: 'alice', email: undefined, grant: true, apply: false,
  });
  for (const args of [[], ['--grant', '--revoke', '--uid', 'alice'], ['--grant', '--uid', 'alice', '--email', 'a@example.com'],
    ['--grant', '--uid', '../alice'], ['--grant', '--uid', 'alice', '--project', 'unrelated-project'],
    ['--grant', '--email', 'invalid'], ['--grant', '--uid', 'alice', '--apply', '--apply']]) {
    assert.throws(() => parseArguments(args));
  }
});

function setup(user, others = []) {
  const calls = [];
  return { calls, auth: {
    getUser: async () => user,
    getUserByEmail: async () => user,
    setCustomUserClaims: async (...args) => calls.push(['claims', ...args]),
    revokeRefreshTokens: async uid => calls.push(['revoke', uid]),
    listUsers: async () => ({ users: [user, ...others] }),
  } };
}

test('dry run does not grant privileges; apply preserves unrelated claims', async () => {
  const { auth, calls } = setup({ uid: 'alice', customClaims: { subscriber: true } });
  const options = parseArguments(['--grant', '--uid', 'alice']);
  assert.equal((await manageAdmin(auth, options)).applied, false);
  assert.equal(calls.length, 0);
  await manageAdmin(auth, { ...options, apply: true });
  assert.deepEqual(calls, [['claims', 'alice', { subscriber: true, admin: true }]]);
});

test('disabled user cannot receive admin; last active admin cannot be removed', async () => {
  const disabled = setup({ uid: 'alice', disabled: true });
  await assert.rejects(manageAdmin(disabled.auth, { uid: 'alice', grant: true, apply: true }));
  const last = setup({ uid: 'alice', customClaims: { admin: true } }, [
    { uid: 'disabled-admin', disabled: true, customClaims: { admin: true } },
  ]);
  await assert.rejects(manageAdmin(last.auth, { uid: 'alice', grant: false, apply: true }), /last active admin/);
  assert.equal(last.calls.length, 0);
});

test('revocation removes only admin claim and revokes refresh tokens', async () => {
  const { auth, calls } = setup({ uid: 'alice', customClaims: { admin: true, subscriber: true } }, [
    { uid: 'bob', customClaims: { admin: true } },
  ]);
  await manageAdmin(auth, { uid: 'alice', grant: false, apply: true });
  assert.deepEqual(calls, [['claims', 'alice', { subscriber: true }], ['revoke', 'alice']]);
});

test('role removal reports partial revocation honestly after claim update succeeds', async () => {
  const { auth } = setup({ uid: 'alice', customClaims: { admin: true } }, [
    { uid: 'bob', customClaims: { admin: true } },
  ]);
  auth.revokeRefreshTokens = async () => { throw new Error('offline'); };
  const result = await manageAdmin(auth, { uid: 'alice', grant: false, apply: true });
  assert.equal(result.applied, true);
  assert.equal(result.sessionRevocationPending, true);
});
