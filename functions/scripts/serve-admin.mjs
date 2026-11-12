import { createServer } from 'node:http';
import { readFile, realpath, stat } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { AdminError, createAdminHandlers } from '../src/admin-service.js';
import { createAdminFirestoreRest } from '../src/admin-firestore-rest.js';

const PROJECT = 'vetalife-24f03';
const PORT = 5178;
const methods = {
  adminListUsers: 'listUsers', adminGetUser: 'getUser',
  adminSetUserDisabled: 'setUserDisabled', adminRevokeUserSessions: 'revokeUserSessions',
  adminUpdateDisplayName: 'updateDisplayName', adminListAuditLogs: 'listAuditLogs',
  adminGetUserJournal: 'getUserJournal', adminGetStatistics: 'getStatistics',
};
const statuses = { unauthenticated: 401, 'permission-denied': 403, 'invalid-argument': 400,
  'not-found': 404, 'failed-precondition': 400, unavailable: 503 };

function sendError(response, code, message) {
  response.writeHead(statuses[code] ?? 503, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify({ error: { status: code.replaceAll('-', '_').toUpperCase(), message } }));
}

/** Exposed for deterministic transport tests; real auth is injected at startup. */
export function createAdminRequestHandler({ auth, handlers, publicDirectory, port = PORT, projectId = PROJECT }) {
  const allowedHosts = new Set([`127.0.0.1:${port}`, `localhost:${port}`]);
  const allowedOrigins = new Set([...allowedHosts].map(host => `http://${host}`));
  const prefix = `/${projectId}/asia-southeast1/`;
  return async (request, response) => {
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('X-Frame-Options', 'DENY');
    response.setHeader('Referrer-Policy', 'same-origin');
    if (!allowedHosts.has(request.headers.host)) return sendError(response, 'permission-denied', 'Local host required.');
    const origin = request.headers.origin;
    if (origin && !allowedOrigins.has(origin)) return sendError(response, 'permission-denied', 'Local origin required.');
    if (origin) {
      response.setHeader('Access-Control-Allow-Origin', origin);
      response.setHeader('Vary', 'Origin');
    }
    let url;
    try { url = new URL(request.url, `http://127.0.0.1:${port}`); }
    catch { return sendError(response, 'invalid-argument', 'Invalid request URL.'); }
    if (url.pathname.startsWith(prefix)) {
      const method = methods[url.pathname.slice(prefix.length)];
      if (!method) return sendError(response, 'not-found', 'Unknown admin operation.');
      if (request.method === 'OPTIONS') {
        response.writeHead(204, { 'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Firebase-AppCheck, Firebase-Instance-ID-Token' });
        return response.end();
      }
      if (request.method !== 'POST') return sendError(response, 'invalid-argument', 'POST required.');
      try {
        if (!/^application\/json(?:\s*;|$)/i.test(request.headers['content-type'] ?? '')) {
          throw new AdminError('invalid-argument', 'JSON required.');
        }
        const token = request.headers.authorization?.match(/^Bearer ([^\s]+)$/)?.[1];
        if (!token) throw new AdminError('unauthenticated', 'Vui lòng đăng nhập quản trị.');
        let decoded;
        try { decoded = await auth.verifyIdToken(token, true); }
        catch { throw new AdminError('unauthenticated', 'Phiên đăng nhập không hợp lệ.'); }
        const chunks = [];
        let bytes = 0;
        for await (const chunk of request) {
          bytes += chunk.length;
          if (bytes > 16384) throw new AdminError('invalid-argument', 'Request too large.');
          chunks.push(chunk);
        }
        let body;
        try { body = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
        catch { throw new AdminError('invalid-argument', 'Invalid JSON.'); }
        if (!body || typeof body !== 'object' || Array.isArray(body) ||
            Object.keys(body).some(key => key !== 'data')) {
          throw new AdminError('invalid-argument', 'Invalid callable envelope.');
        }
        const result = await handlers[method]({ auth: { uid: decoded.uid, token: decoded }, data: body.data });
        response.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
        return response.end(JSON.stringify({ result }));
      } catch (error) {
        if (error instanceof AdminError) return sendError(response, error.code, error.message);
        if (error.code === 'auth/user-not-found') return sendError(response, 'not-found', 'Không tìm thấy người dùng.');
        if (error.code === 'auth/invalid-page-token') return sendError(response, 'invalid-argument', 'Trang không hợp lệ.');
        return sendError(response, 'unavailable', 'Dịch vụ quản trị chưa sẵn sàng. Vui lòng thử lại.');
      }
    }
    if (!['GET', 'HEAD'].includes(request.method)) return sendError(response, 'not-found', 'Not found.');
    try {
      let relative = decodeURIComponent(url.pathname).replace(/^\/+/, '');
      if (!relative) relative = 'index.html';
      if (relative.includes('\\') || relative.split('/').some(part => part.startsWith('.'))) throw new Error('Unsafe path');
      const root = await realpath(publicDirectory);
      let target = path.resolve(root, relative);
      if (!target.startsWith(root + path.sep)) throw new Error('Outside root');
      try { target = await realpath(target); }
      catch {
        if (path.extname(relative)) throw new Error('Missing asset');
        target = path.join(root, 'index.html');
      }
      if (!target.startsWith(root + path.sep) || !(await stat(target)).isFile()) throw new Error('Unsafe target');
      const types = { '.html': 'text/html; charset=utf-8', '.js': 'application/javascript', '.json': 'application/json',
        '.css': 'text/css', '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml',
        '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.ico': 'image/x-icon' };
      response.writeHead(200, { 'Content-Type': types[path.extname(target)] ?? 'application/octet-stream' });
      return response.end(request.method === 'HEAD' ? undefined : await readFile(target));
    } catch {
      return sendError(response, 'not-found', 'Not found. Build the admin web app first.');
    }
  };
}

async function main() {
  if (process.argv.slice(2).some(arg => arg !== '--firebase-cli')) throw new Error('Unknown option.');
  if (process.env.FIREBASE_AUTH_EMULATOR_HOST || process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('This local live server must not mix emulator and production resources.');
  }
  const credential = process.argv.includes('--firebase-cli')
    ? await (await import('./firebase-cli-credential.mjs')).firebaseCliCredential(PROJECT)
    : applicationDefault();
  initializeApp({ projectId: PROJECT, credential });
  const auth = getAuth();
  const firestore = createAdminFirestoreRest({ projectId: PROJECT,
    getAccessToken: async () => (await credential.getAccessToken()).access_token });
  const handlers = createAdminHandlers({ auth, ...firestore });
  const publicDirectory = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..', 'build/admin-web');
  await stat(path.join(publicDirectory, 'index.html'));
  const server = createServer(createAdminRequestHandler({ auth, handlers, publicDirectory }));
  server.requestTimeout = 30000;
  server.headersTimeout = 10000;
  server.listen(PORT, '127.0.0.1', () => {
    // localhost is an authorized Google sign-in domain in this Firebase project.
    console.log(`VetaLife Admin: http://localhost:${PORT}`);
    console.log('Real Firebase project: vetalife-24f03. Browser users must have admin:true. Server is loopback-only.');
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(() => {
    console.error('Admin server could not start. Build admin-web, check trusted credentials and ensure port 5178 is free. Provider details withheld.');
    process.exitCode = 1;
  });
}
