import test from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

// This suite deliberately refuses to fall back to a configured live project.
const PROJECT = 'demo-vetalife-admin';
const AUTH_HOST = '127.0.0.1:9099';
const FIRESTORE_HOST = '127.0.0.1:8080';
if (process.env.FIREBASE_AUTH_EMULATOR_HOST !== AUTH_HOST ||
    process.env.FIRESTORE_EMULATOR_HOST !== FIRESTORE_HOST ||
    process.env.GCLOUD_PROJECT !== PROJECT) {
  throw new Error('Run only with local Auth/Firestore emulators and GCLOUD_PROJECT=demo-vetalife-admin.');
}

const PASSWORD = 'Synthetic-Admin-QA-123!';
const USERS = {
  admin: { uid: 'qa-admin', email: 'admin@example.test', displayName: 'Synthetic Admin' },
  otherAdmin: { uid: 'qa-other-admin', email: 'other-admin@example.test' },
  ordinary: { uid: 'qa-ordinary', email: 'ordinary@example.test' },
  target: { uid: 'qa-target', email: 'target@example.test', displayName: 'Synthetic User' },
  disabledAdmin: { uid: 'qa-disabled-admin', email: 'disabled-admin@example.test' },
};

const app = initializeApp({ projectId: PROJECT }, 'admin-emulator-integration');
const auth = getAuth(app);
const db = getFirestore(app);

async function signIn(email) {
  const response = await fetch(`http://${AUTH_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=emulator-key`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PASSWORD, returnSecureToken: true }),
  });
  const body = await response.json();
  assert.equal(response.status, 200, 'Synthetic emulator user sign-in must succeed');
  assert.equal(typeof body.idToken, 'string');
  return body.idToken;
}

async function callable(name, data, token) {
  const response = await fetch(`http://127.0.0.1:5001/${PROJECT}/asia-southeast1/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify({ data }), signal: AbortSignal.timeout(20000),
  });
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); }
  catch { throw new Error(`Admin callable ${name} unavailable (HTTP ${response.status}); check emulator function discovery.`); }
  return { status: response.status, result: body.result, error: body.error };
}

function succeeded(response) {
  assert.equal(response.status, 200, JSON.stringify(response.error));
  assert.equal(response.error, undefined);
  return response.result;
}

function denied(response, status) {
  assert.notEqual(response.status, 200);
  assert.equal(response.error?.status, status);
  assert.equal(response.result, undefined);
}

test('admin callables enforce real emulator authentication, authorization and account operations', { timeout: 120000 }, async t => {
  const tokens = {};
  try {
    denied(await callable('adminListUsers', {}), 'UNAUTHENTICATED');
    // These explicit emulator URLs cannot delete real Firebase accounts or data.
    const reset = await fetch(`http://${AUTH_HOST}/emulator/v1/projects/${PROJECT}/accounts`, { method: 'DELETE' });
    assert.equal(reset.status, 200);
    for (const [key, user] of Object.entries(USERS)) {
      await auth.createUser({ ...user, password: PASSWORD, emailVerified: true });
      if (['admin', 'otherAdmin', 'disabledAdmin'].includes(key)) {
        await auth.setCustomUserClaims(user.uid, { admin: true, unrelatedClaim: 'preserved' });
      }
      tokens[key] = await signIn(user.email);
    }
    await auth.updateUser(USERS.disabledAdmin.uid, { disabled: true });
    const profile = db.collection('users').doc(USERS.target.uid);
    await profile.set({ displayName: 'Synthetic Profile', birthDate: '2000-01-01', weightKg: 60,
      heightCm: 165, goal: 'recordMeals', privateFutureField: 'must-not-leak' });
    await profile.collection('meals').doc('meal-one').set({ id: 'meal-one' });
    await profile.collection('meals').doc('meal-two').set({ id: 'meal-two' });
    await profile.collection('lessonProgress').doc('p1-ch01').set({ lessonId: 'p1-ch01' });

    await t.test('unauthenticated and ordinary accounts cannot invoke any admin endpoint', async () => {
      const requests = [
        ['adminListUsers', {}], ['adminGetUser', { uid: USERS.target.uid }],
        ['adminSetUserDisabled', { uid: USERS.target.uid, disabled: true }],
        ['adminRevokeUserSessions', { uid: USERS.target.uid }],
      ];
      for (const [name, data] of requests) {
        denied(await callable(name, data), 'UNAUTHENTICATED');
        denied(await callable(name, data, tokens.ordinary), 'PERMISSION_DENIED');
      }
      assert.equal((await auth.getUser(USERS.target.uid)).disabled, false);
    });

    await t.test('admin list returns bounded pages and exact email/UID search without sensitive claims', async () => {
      const first = succeeded(await callable('adminListUsers', { pageSize: 2 }, tokens.admin));
      assert.equal(first.users.length, 2);
      assert.equal(typeof first.nextPageToken, 'string');
      const second = succeeded(await callable('adminListUsers', { pageSize: 2, pageToken: first.nextPageToken }, tokens.admin));
      assert.equal(second.users.length, 2);
      assert.ok(second.users.every(user => !first.users.some(prior => prior.uid === user.uid)));
      const found = succeeded(await callable('adminListUsers', { query: USERS.target.email }, tokens.admin));
      assert.equal(found.users.length, 1);
      assert.equal(found.users[0].uid, USERS.target.uid);
      assert.equal(found.nextPageToken, null);
      assert.equal(found.users[0].customClaims, undefined);
      assert.equal(found.users[0].passwordHash, undefined);
      const byUid = succeeded(await callable('adminListUsers', { query: USERS.target.uid }, tokens.admin));
      assert.equal(byUid.users[0].email, USERS.target.email);
      const absent = succeeded(await callable('adminListUsers', { query: 'missing@example.test' }, tokens.admin));
      assert.deepEqual(absent, { users: [], nextPageToken: null });
    });

    await t.test('admin details use a profile allowlist and actual aggregate activity counts', async () => {
      const detail = succeeded(await callable('adminGetUser', { uid: USERS.target.uid }, tokens.admin));
      assert.equal(detail.user.uid, USERS.target.uid);
      assert.equal(detail.profile.displayName, 'Synthetic Profile');
      assert.equal(detail.profile.privateFutureField, undefined);
      assert.deepEqual(detail.activity, { mealCount: 2, readLessonCount: 1 });
      const empty = succeeded(await callable('adminGetUser', { uid: USERS.ordinary.uid }, tokens.admin));
      assert.equal(empty.profile, null);
      assert.deepEqual(empty.activity, { mealCount: 0, readLessonCount: 0 });
    });

    await t.test('invalid payloads cannot disable users or bypass validation', async () => {
      for (const data of [{ uid: '../bad' }, { uid: USERS.target.uid, extra: true }]) {
        denied(await callable('adminGetUser', data, tokens.admin), 'INVALID_ARGUMENT');
      }
      denied(await callable('adminListUsers', { pageSize: 101 }, tokens.admin), 'INVALID_ARGUMENT');
      denied(await callable('adminListUsers', { pageToken: 'next', query: USERS.target.email }, tokens.admin), 'INVALID_ARGUMENT');
      denied(await callable('adminSetUserDisabled', { uid: USERS.target.uid, disabled: 'true' }, tokens.admin), 'INVALID_ARGUMENT');
      assert.equal((await auth.getUser(USERS.target.uid)).disabled, false);
    });

    await t.test('self and other admin accounts are protected against disable and session revocation', async () => {
      for (const uid of [USERS.admin.uid, USERS.otherAdmin.uid]) {
        denied(await callable('adminSetUserDisabled', { uid, disabled: true }, tokens.admin), 'FAILED_PRECONDITION');
        denied(await callable('adminRevokeUserSessions', { uid }, tokens.admin), 'FAILED_PRECONDITION');
        assert.equal((await auth.getUser(uid)).disabled, false);
      }
    });

    await t.test('account disable/enable and refresh-session revocation persist with completed audit records', async () => {
      const disabled = succeeded(await callable('adminSetUserDisabled', { uid: USERS.target.uid, disabled: true }, tokens.admin));
      assert.equal(disabled.disabled, true);
      assert.equal((await auth.getUser(USERS.target.uid)).disabled, true);
      const enabled = succeeded(await callable('adminSetUserDisabled', { uid: USERS.target.uid, disabled: false }, tokens.admin));
      assert.equal(enabled.disabled, false);
      assert.equal((await auth.getUser(USERS.target.uid)).disabled, false);
      const before = Date.parse((await auth.getUser(USERS.target.uid)).tokensValidAfterTime);
      const revoked = succeeded(await callable('adminRevokeUserSessions', { uid: USERS.target.uid }, tokens.admin));
      assert.equal(revoked.revoked, true);
      assert.ok(Date.parse((await auth.getUser(USERS.target.uid)).tokensValidAfterTime) >= before);
      const audits = await db.collection('adminAuditLogs').where('actorUid', '==', USERS.admin.uid).get();
      const actions = audits.docs.filter(doc => doc.data().targetUid === USERS.target.uid).map(doc => doc.data());
      for (const action of ['disable-user', 'enable-user', 'revoke-sessions']) {
        const record = actions.find(item => item.action === action);
        assert.ok(record, `${action} must have a durable audit record`);
        assert.equal(record.status, 'completed');
        assert.ok(record.createdAt);
        assert.ok(record.completedAt);
      }
    });

    await t.test('disabled admin cannot use an existing token', async () => {
      denied(await callable('adminListUsers', {}, tokens.disabledAdmin), 'PERMISSION_DENIED');
    });

    await t.test('live role removal denies stale administrator tokens immediately', async () => {
      await auth.setCustomUserClaims(USERS.otherAdmin.uid, { admin: false });
      denied(await callable('adminListUsers', {}, tokens.otherAdmin), 'PERMISSION_DENIED');
    });

    await t.test('Firestore rules deny direct audit reads even to an admin claim', async () => {
      for (const token of [undefined, tokens.ordinary, tokens.admin]) {
        const response = await fetch(`http://${FIRESTORE_HOST}/v1/projects/${PROJECT}/databases/(default)/documents/adminAuditLogs`, {
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        });
        assert.equal(response.status, 403);
      }
    });
  } finally {
    await db.terminate();
    await deleteApp(app);
  }
});
