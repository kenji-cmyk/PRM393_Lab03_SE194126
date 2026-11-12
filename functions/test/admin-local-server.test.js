import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer, request as httpRequest } from 'node:http';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { createAdminRequestHandler } from '../scripts/serve-admin.mjs';
import { AdminError } from '../src/admin-service.js';

async function setup(t) {
  const directory = await mkdtemp(path.join(tmpdir(), 'vetalife-admin-transport-'));
  await writeFile(path.join(directory, 'index.html'), '<title>VetaLife Admin</title>');
  const calls = [];
  const server = createServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const port = server.address().port;
  server.on('request', createAdminRequestHandler({ publicDirectory: directory, port,
    auth: { verifyIdToken: async (token, checkRevoked) => {
      calls.push({ token, checkRevoked });
      if (token !== 'valid-token') throw new Error('secret provider details');
      return { uid: 'admin-test', admin: true, auth_time: 123 };
    } },
    handlers: {
      listUsers: async request => ({ users: [{ uid: request.auth.uid }], nextPageToken: null }),
      setUserDisabled: async () => { throw new AdminError('permission-denied', 'Role removed.'); },
      getUser: async () => { throw new Error('private@example.com secret provider error'); },
    },
  }));
  t.after(async () => {
    await new Promise(resolve => server.close(resolve));
    await rm(directory, { recursive: true, force: true });
  });
  const base = `http://127.0.0.1:${port}`;
  const call = (method, overrides = {}) => fetch(`${base}/vetalife-24f03/asia-southeast1/${method}`, {
    method: 'POST', body: JSON.stringify({ data: {} }),
    ...overrides,
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer valid-token', ...overrides.headers },
  });
  return { base, call, calls };
}

test('local API verifies real tokens with revocation checking and returns callable envelope', async t => {
  const { call, calls } = await setup(t);
  const result = await call('adminListUsers');
  assert.equal(result.status, 200);
  assert.deepEqual(await result.json(), { result: { users: [{ uid: 'admin-test' }], nextPageToken: null } });
  assert.deepEqual(calls, [{ token: 'valid-token', checkRevoked: true }]);
});

test('local API rejects unauthenticated requests and invalid tokens without provider disclosure', async t => {
  const { call } = await setup(t);
  for (const token of ['', 'Bearer invalid-token']) {
    const result = await call('adminListUsers', { headers: { Authorization: token } });
    assert.equal(result.status, 401);
    assert.equal((await result.json()).error.status, 'UNAUTHENTICATED');
  }
});

test('local API refuses remote browser origins, DNS-rebinding hosts and unknown methods', async t => {
  const { call } = await setup(t);
  assert.equal((await call('adminListUsers', { headers: { Origin: 'https://attacker.invalid' } })).status, 403);
  // fetch normalizes Host. Use the raw HTTP client to exercise rebinding.
  const { base } = await setup(t);
  const hostStatus = await new Promise((resolve, reject) => {
    const request = httpRequest(base, { headers: { Host: 'attacker.invalid' } }, response => {
      response.resume();
      resolve(response.statusCode);
    });
    request.on('error', reject);
    request.end();
  });
  assert.equal(hostStatus, 403);
  assert.equal((await call('unknown')).status, 404);
});

test('local API propagates authorization failure, sanitizes unexpected errors and validates envelopes', async t => {
  const { call } = await setup(t);
  assert.equal((await call('adminSetUserDisabled')).status, 403);
  const providerFailure = await call('adminGetUser');
  assert.equal(providerFailure.status, 503);
  assert.ok(!(await providerFailure.text()).includes('private@example.com'));
  for (const body of ['bad-json', '[]', '{"data":{},"extra":true}', JSON.stringify({ data: 'x'.repeat(17000) })]) {
    assert.equal((await call('adminListUsers', { body })).status, 400);
  }
});

test('local server serves built app, blocks dotfiles and sends security headers', async t => {
  const { base } = await setup(t);
  const index = await fetch(base);
  assert.equal(index.status, 200);
  assert.ok((await index.text()).includes('VetaLife Admin'));
  assert.equal(index.headers.get('cache-control'), 'no-store');
  assert.equal(index.headers.get('x-frame-options'), 'DENY');
  assert.equal((await fetch(`${base}/.env`)).status, 404);
  assert.equal((await fetch(`${base}/absent.js`)).status, 404);
});

test('malformed request targets return 400 and leave local server available', async t => {
  const { base } = await setup(t);
  const status = await new Promise((resolve, reject) => {
    const request = httpRequest(base, { path: 'http://[' }, response => {
      response.resume();
      resolve(response.statusCode);
    });
    request.on('error', reject);
    request.end();
  });
  assert.equal(status, 400);
  assert.equal((await fetch(base)).status, 200);
});
