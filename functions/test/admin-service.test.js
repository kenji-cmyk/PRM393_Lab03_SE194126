import test from 'node:test';
import assert from 'node:assert/strict';
import { createAdminHandlers } from '../src/admin-service.js';

const request = (data = {}, auth = { uid: 'admin', token: { auth_time: 2000 } }) => ({ auth, data });
const code = (expected) => (error) => error.code === expected;

function setup(overrides = {}) {
  const users = new Map([
    ['admin', { uid: 'admin', customClaims: { admin: true }, tokensValidAfterTime: new Date(1000 * 1000).toUTCString() }],
    ['alice', { uid: 'alice', email: 'alice@example.test', displayName: 'Alice', disabled: false,
      customClaims: { privateClaim: 'never-return' }, metadata: { creationTime: 'created', lastSignInTime: 'signed-in' },
      providerData: [{ privateData: 'never-return' }] }],
    ['other-admin', { uid: 'other-admin', customClaims: { admin: true } }],
  ]);
  const events = [];
  const auth = {
    getUser: async (uid) => {
      events.push(['getUser', uid]);
      if (!users.has(uid)) throw Object.assign(new Error('private provider text'), { code: 'auth/user-not-found' });
      return users.get(uid);
    },
    getUserByEmail: async (email) => {
      events.push(['email', email]);
      const user = [...users.values()].find((value) => value.email === email);
      if (!user) throw Object.assign(new Error('private provider text'), { code: 'auth/user-not-found' });
      return user;
    },
    listUsers: async (limit, token) => {
      events.push(['list', limit, token]);
      return { users: [users.get('alice')], pageToken: 'next-page' };
    },
    updateUser: async (uid, fields) => { events.push(['update', uid, fields]); return { ...users.get(uid), ...fields }; },
    revokeRefreshTokens: async (uid) => { events.push(['revoke', uid]); },
    ...overrides.auth,
  };
  const service = createAdminHandlers({
    auth,
    loadProfile: async (uid) => { events.push(['profile', uid]); return { displayName: 'Alice' }; },
    countActivity: async (uid) => { events.push(['count', uid]); return { mealCount: 3, readLessonCount: 2 }; },
    beginAudit: async (data) => { events.push(['audit-start', data]); return 'audit-1'; },
    finishAudit: async (id, data) => { events.push(['audit-finish', id, data]); },
    loadAuditLogs: async (data) => { events.push(['logs', data]); return { logs: [], nextId: null }; },
    ...Object.fromEntries(Object.entries(overrides).filter(([key]) => key !== 'auth')),
  });
  return { service, users, events };
}

test('all endpoints deny anonymous requests before Auth/data access', async () => {
  const { service, events } = setup();
  for (const operation of Object.values(service)) await assert.rejects(operation(request({}, null)), code('unauthenticated'));
  assert.deepEqual(events, []);
});

test('live role and disabled state override stale claimed admin role', async () => {
  for (const update of [{ customClaims: {} }, { disabled: true }]) {
    const { service, users, events } = setup();
    users.set('admin', { ...users.get('admin'), ...update });
    await assert.rejects(service.listUsers(request({}, { uid: 'admin', token: { admin: true, auth_time: 2000 } })), code('permission-denied'));
    assert.deepEqual(events, [['getUser', 'admin']]);
  }
});

test('revoked, missing and malformed auth_time cannot access admin data', async () => {
  for (const authTime of [999, undefined, '2000', NaN, Infinity, 0]) {
    const { service, events } = setup();
    await assert.rejects(service.listUsers(request({}, { uid: 'admin', token: { auth_time: authTime } })), code('unauthenticated'));
    assert.deepEqual(events, [['getUser', 'admin']]);
  }
});

test('deleted admin caller is unauthenticated and cannot access data', async () => {
  const { service, users, events } = setup();
  users.delete('admin');
  await assert.rejects(service.getUser(request({ uid: 'alice' })), code('unauthenticated'));
  assert.deepEqual(events, [['getUser', 'admin']]);
});

test('list respects bounded pagination and exposes only safe summaries', async () => {
  const { service, events } = setup();
  const result = await service.listUsers(request({ pageSize: 10, pageToken: 'previous-page' }));
  assert.deepEqual(events.at(-1), ['list', 10, 'previous-page']);
  assert.equal(result.nextPageToken, 'next-page');
  assert.deepEqual(result.users[0], {
    uid: 'alice', email: 'alice@example.test', displayName: 'Alice', photoUrl: null,
    disabled: false, emailVerified: false, isAdmin: false, createdAt: 'created', lastSignInAt: 'signed-in',
  });
  assert.ok(!JSON.stringify(result).includes('never-return'));
});

test('default page size is 25 and missing next token becomes null', async () => {
  const { service, events } = setup({ auth: { listUsers: async (limit) => { events.push(['limit', limit]); return { users: [] }; } } });
  assert.deepEqual(await service.listUsers(request()), { users: [], nextPageToken: null });
  assert.deepEqual(events.at(-1), ['limit', 25]);
});

test('malformed list payloads reject before listing users', async () => {
  for (const data of [[], 'bad', { pageSize: 101 }, { pageSize: 0 }, { pageSize: 1.5 }, { pageToken: '' },
    { pageToken: 'x'.repeat(2049) }, { query: '' }, { query: ' alice ' }, { query: 'a'.repeat(321) },
    { query: 'alice', pageToken: 'next' }, { customClaims: { admin: true } }]) {
    const { service, events } = setup();
    await assert.rejects(service.listUsers(request(data)), code('invalid-argument'));
    assert.deepEqual(events, [['getUser', 'admin']]);
  }
});

test('exact email and UID searches use indexed Auth lookups without scanning', async () => {
  for (const query of ['alice', 'alice@example.test']) {
    const { service, events } = setup();
    const result = await service.listUsers(request({ query }));
    assert.equal(result.users[0].uid, 'alice');
    assert.equal(result.nextPageToken, null);
    assert.ok(!events.some(([kind]) => kind === 'list'));
  }
  assert.deepEqual(await setup().service.listUsers(request({ query: 'missing' })), { users: [], nextPageToken: null });
});

test('details return profile and aggregate activity only for an existing target', async () => {
  const { service, events } = setup();
  const result = await service.getUser(request({ uid: 'alice' }));
  assert.deepEqual(result.profile, { displayName: 'Alice' });
  assert.deepEqual(result.activity, { mealCount: 3, readLessonCount: 2 });
  await assert.rejects(service.getUser(request({ uid: 'missing' })), code('not-found'));
  assert.equal(events.filter(([kind]) => kind === 'profile').length, 1);
});

test('UID validation prevents document traversal or unbounded input', async () => {
  for (const uid of ['', 'a/b', ' a', 'a ', 'a\nb', 'x'.repeat(129), 12, null]) {
    const { service, events } = setup();
    await assert.rejects(service.getUser(request({ uid })), code('invalid-argument'));
    await assert.rejects(service.setUserDisabled(request({ uid, disabled: true })), code('invalid-argument'));
    await assert.rejects(service.revokeUserSessions(request({ uid })), code('invalid-argument'));
    assert.ok(!events.some(([kind]) => ['update', 'revoke', 'audit-start'].includes(kind)));
  }
});

test('self and other admin accounts cannot be disabled or revoked', async () => {
  for (const uid of ['admin', 'other-admin']) {
    const { service, events } = setup();
    await assert.rejects(service.setUserDisabled(request({ uid, disabled: true })), code('failed-precondition'));
    await assert.rejects(service.revokeUserSessions(request({ uid })), code('failed-precondition'));
    assert.ok(!events.some(([kind]) => ['update', 'revoke', 'audit-start'].includes(kind)));
  }
});

test('disable and enable require explicit boolean and reject injected fields', async () => {
  for (const data of [{ uid: 'alice', disabled: 'true' }, { uid: 'alice' }, { uid: 'alice', disabled: true, admin: true }]) {
    await assert.rejects(setup().service.setUserDisabled(request(data)), code('invalid-argument'));
  }
  for (const disabled of [true, false]) {
    const { service, events } = setup();
    assert.deepEqual(await service.setUserDisabled(request({ uid: 'alice', disabled })), { uid: 'alice', disabled });
    assert.equal(events.findIndex(([kind]) => kind === 'audit-start') < events.findIndex(([kind]) => kind === 'update'), true);
    assert.deepEqual(events.at(-1), ['audit-finish', 'audit-1', { status: 'completed' }]);
    const audit = events.find(([kind]) => kind === 'audit-start')[1];
    assert.deepEqual(audit, { actorUid: 'admin', targetUid: 'alice', action: disabled ? 'disable-user' : 'enable-user', status: 'attempted' });
  }
});

test('session revocation is audited and returns success only after Auth operation', async () => {
  const { service, events } = setup();
  assert.deepEqual(await service.revokeUserSessions(request({ uid: 'alice' })), { uid: 'alice', revoked: true });
  assert.deepEqual(events.slice(-3).map(([kind]) => kind), ['audit-start', 'revoke', 'audit-finish']);
});

test('initial audit failure prevents Auth mutation', async () => {
  const { service, events } = setup({ beginAudit: async () => { throw new Error('audit unavailable'); } });
  await assert.rejects(service.setUserDisabled(request({ uid: 'alice', disabled: true })), /audit unavailable/);
  assert.ok(!events.some(([kind]) => kind === 'update'));
});

test('failed Auth action is audited as failed; successful action survives final audit outage', async () => {
  const failed = setup({ auth: { revokeRefreshTokens: async () => { throw new Error('auth outage'); } } });
  await assert.rejects(failed.service.revokeUserSessions(request({ uid: 'alice' })), /auth outage/);
  assert.deepEqual(failed.events.at(-1), ['audit-finish', 'audit-1', { status: 'failed' }]);
  const partial = setup({ finishAudit: async () => { throw new Error('audit outage'); } });
  assert.deepEqual(await partial.service.setUserDisabled(request({ uid: 'alice', disabled: true })), { uid: 'alice', disabled: true, auditWarning: true });
  assert.equal(partial.events.filter(([kind]) => kind === 'update').length, 1);
});

test('display name edits validate strictly and preserve protected account boundaries', async () => {
  for (const displayName of ['', ' Alice ', 'x'.repeat(101), 'Alice\nBob', null]) {
    await assert.rejects(setup().service.updateDisplayName(request({ uid: 'alice', displayName })), code('invalid-argument'));
  }
  for (const uid of ['admin', 'other-admin']) {
    const { service, events } = setup();
    await assert.rejects(service.updateDisplayName(request({ uid, displayName: 'New name' })), code('failed-precondition'));
    assert.ok(!events.some(([kind]) => kind === 'update'));
  }
  const { service, events } = setup();
  await service.updateDisplayName(request({ uid: 'alice', displayName: 'Tên mới' }));
  assert.deepEqual(events.slice(-3).map(([kind]) => kind), ['audit-start', 'update', 'audit-finish']);
  assert.deepEqual(events.find(([kind]) => kind === 'update'), ['update', 'alice', { displayName: 'Tên mới' }]);
  assert.equal(events.find(([kind]) => kind === 'audit-start')[1].action, 'update-display-name');
  await assert.rejects(service.updateDisplayName(request({ uid: 'alice', displayName: 'New', admin: true })), code('invalid-argument'));
});

test('audit pagination binds its cursor to target filter and validates bounded requests', async () => {
  const { service, events } = setup({ loadAuditLogs: async data => {
    events.push(['logs', data]); return { logs: [{ id: 'audit-1', status: 'attempted' }], nextId: 'audit-1' };
  } });
  const first = await service.listAuditLogs(request({ targetUid: 'alice', pageSize: 1 }));
  assert.equal(first.logs[0].status, 'attempted');
  await service.listAuditLogs(request({ targetUid: 'alice', pageToken: first.nextPageToken }));
  assert.deepEqual(events.at(-1), ['logs', { pageSize: 25, targetUid: 'alice', afterId: 'audit-1' }]);
  for (const data of [{ pageToken: first.nextPageToken }, { targetUid: 'bob', pageToken: first.nextPageToken },
    { pageSize: 101 }, { pageSize: 0 }, { targetUid: 'a/b' }, { pageToken: 'bad' }, { status: 'failed' }]) {
    await assert.rejects(service.listAuditLogs(request(data)), code('invalid-argument'));
  }
});

test('new endpoints deny stale roles before reaching logs or modifying names', async () => {
  const { service, users, events } = setup();
  users.set('admin', { uid: 'admin', customClaims: {} });
  await assert.rejects(service.listAuditLogs(request()), code('permission-denied'));
  await assert.rejects(service.getStatistics(request()), code('permission-denied'));
  await assert.rejects(service.getUserJournal(request({ uid: 'alice' })), code('permission-denied'));
  await assert.rejects(service.updateDisplayName(request({ uid: 'alice', displayName: 'New' })), code('permission-denied'));
  assert.ok(!events.some(([kind]) => ['logs', 'update', 'audit-start'].includes(kind)));
});

test('journal validates target, page size and UID-bound cursors before data access', async () => {
  const calls = [];
  const { service } = setup({ loadUserJournal: async data => {
    calls.push(data); return { meals: [{ id: 'meal-1', name: 'Rice' }], nextId: 'meal-1' };
  } });
  const page = await service.getUserJournal(request({ uid: 'alice' }));
  assert.equal(page.meals[0].name, 'Rice');
  await service.getUserJournal(request({ uid: 'alice', pageToken: page.nextPageToken }));
  assert.deepEqual(calls[1], { uid: 'alice', pageSize: 20, afterId: 'meal-1' });
  for (const data of [{ uid: 'other-admin', pageToken: page.nextPageToken },
    { uid: 'alice', pageSize: 51 }, { uid: 'alice', pageSize: 0 }, { uid: 'alice', pageToken: 'bad' }]) {
    await assert.rejects(service.getUserJournal(request(data)), code('invalid-argument'));
  }
  await assert.rejects(service.getUserJournal(request({ uid: 'missing' })), code('not-found'));
  assert.equal(calls.length, 2);
});

test('statistics aggregates Auth pages at a fixed clock with explicit complete scope', async () => {
  const pages = [];
  const { service } = setup({ now: () => new Date('2026-11-12T00:00:00Z'), auth: {
    listUsers: async (limit, token) => {
      pages.push({ limit, token });
      return token ? { users: [{ uid: 'b', disabled: true, metadata: { creationTime: '2026-10-20T00:00:00Z' } }] }
        : { users: [{ uid: 'a', emailVerified: true, customClaims: { admin: true },
          metadata: { creationTime: '2026-11-10T00:00:00Z', lastSignInTime: '2026-11-11T00:00:00Z' } }], pageToken: 'next' };
    },
  } });
  assert.deepEqual(await service.getStatistics(request()), { scannedUsers: 2, isComplete: true,
    active: 1, disabled: 1, admins: 1, verified: 1, newUsers7d: 1, newUsers30d: 2,
    signedIn7d: 1, signedIn30d: 1, generatedAt: '2026-11-12T00:00:00.000Z' });
  assert.equal(pages.length, 2);
  await assert.rejects(service.getStatistics(request({ uid: 'alice' })), code('invalid-argument'));
});

test('statistics caps scans and never claims an incomplete sample is global', async () => {
  let calls = 0;
  const { service } = setup({ auth: { listUsers: async () => {
    calls++; return { users: Array.from({ length: 1000 }, (_, index) => ({ uid: String(index) })), pageToken: 'more' };
  } } });
  const stats = await service.getStatistics(request());
  assert.equal(calls, 2);
  assert.equal(stats.scannedUsers, 2000);
  assert.equal(stats.isComplete, false);
  const broken = setup({ auth: { listUsers: async () => { throw new Error('data outage'); } } });
  await assert.rejects(broken.service.getStatistics(request()), /data outage/);
});
