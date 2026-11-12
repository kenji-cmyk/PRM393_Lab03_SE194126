import test from 'node:test';
import assert from 'node:assert/strict';
import { createAdminFirestoreRest } from '../src/admin-firestore-rest.js';

const id = '11111111-2222-4333-8444-555555555555';
const root = 'https://firestore.googleapis.com/v1/projects/vetalife-24f03/databases/(default)/documents';
const resourceRoot = 'projects/vetalife-24f03/databases/(default)/documents';
const now = new Date('2026-11-12T05:00:00Z');
const ok = (value, status = 200) => ({ ok: status >= 200 && status < 300, status, json: async () => value });
const code = (expected) => (error) => error.code === expected;

function setup(response = ok({}), overrides = {}) {
  const calls = [];
  const adapter = createAdminFirestoreRest({
    projectId: 'vetalife-24f03', getAccessToken: async () => 'secret-access-token', now: () => now,
    createUuid: () => id,
    fetchImpl: async (url, options) => { calls.push({ url, ...options, body: options.body ? JSON.parse(options.body) : undefined }); return typeof response === 'function' ? response(url, options) : response; },
    ...overrides,
  });
  return { adapter, calls };
}

test('profile lookup uses encoded ID, trusted origin, timeout and in-memory bearer token', async () => {
  const { adapter, calls } = setup(ok({ fields: { displayName: { stringValue: 'Alice' } } }));
  assert.deepEqual(await adapter.loadProfile('user@example.test'), { displayName: 'Alice' });
  assert.equal(calls[0].url, `${root}/users/user%40example.test`);
  assert.equal(calls[0].headers.Authorization, 'Bearer secret-access-token');
  assert.equal(calls[0].redirect, 'error');
  assert.ok(calls[0].signal instanceof AbortSignal);
  assert.equal(calls[0].method, 'GET');
});

test('profile decoder allows selected fields only and excludes nonfinite or wrong types', async () => {
  const { adapter } = setup(ok({ fields: {
    displayName: { stringValue: 'x'.repeat(220) }, birthDate: { stringValue: '2000-01-01' }, goal: { stringValue: 'readDaily' },
    weightKg: { integerValue: '60' }, heightCm: { doubleValue: 165.5 }, privateData: { stringValue: 'secret' },
  } }));
  assert.deepEqual(await adapter.loadProfile('alice'), { displayName: 'x'.repeat(200), birthDate: '2000-01-01', goal: 'readDaily', weightKg: 60, heightCm: 165.5 });
  const invalid = setup(ok({ fields: { weightKg: { doubleValue: Infinity }, heightCm: { stringValue: '165' }, birthDate: { integerValue: '12' } } }));
  assert.deepEqual(await invalid.adapter.loadProfile('alice'), {});
});

test('missing profile is null; malformed document fails closed', async () => {
  assert.equal(await setup(ok({}, 404)).adapter.loadProfile('alice'), null);
  for (const value of [null, [], { fields: [] }, 'raw response']) {
    await assert.rejects(setup(ok(value)).adapter.loadProfile('alice'), code('unavailable'));
  }
  assert.deepEqual(await setup(ok({ name: `${resourceRoot}/users/alice` })).adapter.loadProfile('alice'), {});
});

test('activity executes two count aggregation queries under the target user', async () => {
  const { adapter, calls } = setup((url, options) => ok([{ result: { aggregateFields: { count: { integerValue: JSON.parse(options.body).structuredAggregationQuery.structuredQuery.from[0].collectionId === 'meals' ? '4' : '2' } } } }]));
  assert.deepEqual(await adapter.countActivity('alice'), { mealCount: 4, readLessonCount: 2 });
  assert.equal(calls.length, 2);
  for (const call of calls) {
    assert.equal(call.url, `${root}/users/alice:runAggregationQuery`);
    assert.equal(call.method, 'POST');
    assert.deepEqual(call.body.structuredAggregationQuery.aggregations, [{ alias: 'count', count: {} }]);
  }
  assert.deepEqual(calls.map((call) => call.body.structuredAggregationQuery.structuredQuery.from[0].collectionId), ['meals', 'lessonProgress']);
});

test('aggregation rejects missing, negative, overflowing, duplicate or malformed counts', async () => {
  for (const value of [[], {}, [{}], [{ result: {} }],
    [{ result: { aggregateFields: { count: { integerValue: '-1' } } } }],
    [{ result: { aggregateFields: { count: { integerValue: '9007199254740992' } } } }],
    [{ result: { aggregateFields: { count: { integerValue: 1 } } } }],
    [{ result: { aggregateFields: { count: { doubleValue: 2 } } } }],
    [{ result: { aggregateFields: { count: { integerValue: '1' } } } }, { result: { aggregateFields: { count: { integerValue: '2' } } } }],
  ]) await assert.rejects(setup(ok(value)).adapter.countActivity('alice'), code('unavailable'));
  assert.deepEqual(await setup(ok([{ readTime: 'now' }, { result: { aggregateFields: { count: { integerValue: '0' } } } }])).adapter.countActivity('alice'), { mealCount: 0, readLessonCount: 0 });
});

test('audit create sends only allowed fields with generated ID and explicit timestamp', async () => {
  const { adapter, calls } = setup(ok({ name: `${resourceRoot}/adminAuditLogs/${id}` }));
  assert.equal(await adapter.beginAudit({ actorUid: 'admin', targetUid: 'alice', action: 'disable-user', status: 'attempted' }), id);
  assert.equal(calls[0].url, `${root}/adminAuditLogs?documentId=${id}`);
  assert.equal(calls[0].method, 'POST');
  assert.deepEqual(calls[0].body, { fields: {
    actorUid: { stringValue: 'admin' }, targetUid: { stringValue: 'alice' }, action: { stringValue: 'disable-user' },
    status: { stringValue: 'attempted' }, createdAt: { timestampValue: now.toISOString() },
  } });
  await assert.rejects(setup(ok({})).adapter.beginAudit({ actorUid: 'admin', targetUid: 'alice', action: 'disable-user', status: 'attempted' }), code('unavailable'));
});

test('audit finish uses explicit update mask and existing-document precondition', async () => {
  const { adapter, calls } = setup(ok({}));
  await adapter.finishAudit(id, { status: 'completed' });
  const url = new URL(calls[0].url);
  assert.equal(url.pathname, new URL(`${root}/adminAuditLogs/${id}`).pathname);
  assert.deepEqual(url.searchParams.getAll('updateMask.fieldPaths'), ['status', 'completedAt']);
  assert.equal(url.searchParams.get('currentDocument.exists'), 'true');
  assert.equal(calls[0].method, 'PATCH');
  assert.deepEqual(calls[0].body, { fields: { status: { stringValue: 'completed' }, completedAt: { timestampValue: now.toISOString() } } });
});

test('invalid UID, audit entries and project cannot redirect credentials or inject fields', async () => {
  const { adapter, calls } = setup();
  for (const uid of ['a/b', '../adminAuditLogs', ' alice', 'x'.repeat(129), 'a\nb']) {
    await assert.rejects(adapter.loadProfile(uid), code('invalid-argument'));
    await assert.rejects(adapter.countActivity(uid), code('invalid-argument'));
  }
  await assert.rejects(adapter.beginAudit({ actorUid: 'admin', targetUid: 'alice', action: 'disable-user', status: 'attempted', accessToken: 'secret' }), code('invalid-argument'));
  await assert.rejects(adapter.finishAudit('../alice', { status: 'completed' }), code('invalid-argument'));
  await assert.rejects(adapter.finishAudit(id, { status: 'completed', actorUid: 'another' }), code('invalid-argument'));
  assert.equal(calls.length, 0);
  for (const projectId of ['https://evil.test', 'a/b', 'vetalife-24f03?x=y', 'bad\nproject']) {
    assert.throws(() => setup(ok({}), { projectId }), code('failed-precondition'));
  }
});

test('HTTP, credential, network, redirect and parse failures withhold all provider details', async () => {
  for (const overrides of [
    { getAccessToken: async () => { throw new Error('secret-access-token provider text'); } },
    { fetchImpl: async () => { throw new Error('secret-access-token network URL'); } },
    { fetchImpl: async () => ok({ error: { message: 'secret-access-token provider text' } }, 403) },
    { fetchImpl: async () => ({ ok: true, json: async () => { throw new Error('secret-access-token'); } }) },
    { fetchImpl: async () => ok({}, 302) },
    { getAccessToken: async () => '' },
  ]) {
    await assert.rejects(setup(ok({}), overrides).adapter.loadProfile('alice'), (error) => error.code === 'unavailable' && !error.message.includes('secret-access-token'));
  }
});

test('adapter supports Admin SDK credential response without writing token to body', async () => {
  const { adapter, calls } = setup(ok({ fields: {} }), { getAccessToken: async () => ({ access_token: 'secret-token', expires_in: 3600 }) });
  assert.deepEqual(await adapter.loadProfile('alice'), {});
  assert.equal(calls[0].headers.Authorization, 'Bearer secret-token');
  assert.equal(calls[0].body, undefined);
});
