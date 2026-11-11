import test from 'node:test';
import assert from 'node:assert/strict';
import { v2 as cloudinary } from 'cloudinary';
import {
  MAX_REPORT_BYTES,
  REPORT_DOWNLOAD_TTL_SECONDS,
  createReportHandlers,
  isValidReportPublicId,
  reportOwnerPrefix,
} from '../src/report-service.js';

const UUID_ALICE = '11111111-2222-4333-8444-555555555555';
const BASE_CONFIG = {
  cloudName: 'demo-cloud',
  apiKey: 'demo-api-key',
  apiSecret: 'demo-api-secret',
  uploadPreset: 'vetalife-reports-signed',
};

const code = (expected) => (error) => error.code === expected;

function setup(overrides = {}) {
  return createReportHandlers({
    getConfig: () => BASE_CONFIG,
    now: () => new Date('2026-11-11T02:00:00Z'),
    createUuid: () => UUID_ALICE,
    ...overrides,
  });
}

test('report callables reject unauthenticated and malformed UIDs before reading config', () => {
  let configReads = 0;
  const handlers = setup({
    getConfig: () => {
      configReads++;
      return BASE_CONFIG;
    },
  });
  for (const auth of [undefined, null, {}, { uid: '' }, { uid: 'a/b' }, { uid: 'x'.repeat(129) }]) {
    assert.throws(() => handlers.createUploadSignature({ auth }), code('unauthenticated'));
    assert.throws(
      () => handlers.getDownloadUrl({ auth, data: { publicId: `u_YWJj/reports/${UUID_ALICE}.pdf` } }),
      code('unauthenticated'),
    );
  }
  assert.equal(configReads, 0);
});

test('report callables fail explicitly with failed-precondition when Cloudinary config is incomplete', () => {
  for (const patch of [
    { cloudName: '' },
    { apiKey: '   ' },
    { apiSecret: '' },
  ]) {
    const handlers = setup({ getConfig: () => ({ ...BASE_CONFIG, ...patch }) });
    assert.throws(
      () => handlers.createUploadSignature({ auth: { uid: 'alice' } }),
      code('failed-precondition'),
    );
    assert.throws(
      () => handlers.getDownloadUrl({
        auth: { uid: 'alice' },
        data: { publicId: `${reportOwnerPrefix('alice')}${UUID_ALICE}.pdf` },
      }),
      code('failed-precondition'),
    );
  }

  const noPreset = setup({ getConfig: () => ({ ...BASE_CONFIG, uploadPreset: '' }) });
  assert.throws(
    () => noPreset.createUploadSignature({ auth: { uid: 'alice' } }),
    code('failed-precondition'),
  );
});

test('createUploadSignature generates owner-scoped publicId and authentic Cloudinary signature', () => {
  const handlers = setup();
  const uid = 'alice_test-123';
  const response = handlers.createUploadSignature({ auth: { uid } });
  const expectedPrefix = reportOwnerPrefix(uid);
  assert.equal(expectedPrefix, 'u_YWxpY2VfdGVzdC0xMjM/reports/');
  assert.equal(response.cloudName, BASE_CONFIG.cloudName);
  assert.equal(response.apiKey, BASE_CONFIG.apiKey);
  assert.equal(response.uploadPreset, BASE_CONFIG.uploadPreset);
  assert.equal(response.resourceType, 'raw');
  assert.equal(response.deliveryType, 'authenticated');
  assert.equal(response.maxBytes, MAX_REPORT_BYTES);
  assert.equal(response.publicId, `${expectedPrefix}${UUID_ALICE}.pdf`);
  assert.equal(response.timestamp, Math.floor(Date.parse('2026-11-11T02:00:00Z') / 1000));

  const expectedSig = cloudinary.utils.api_sign_request(
    {
      public_id: response.publicId,
      timestamp: response.timestamp,
      type: 'authenticated',
      upload_preset: BASE_CONFIG.uploadPreset,
      overwrite: false,
    },
    BASE_CONFIG.apiSecret,
  );
  assert.equal(response.signature, expectedSig);
  assert.match(response.signature, /^[0-9a-f]{40}$/);
});

test('getDownloadUrl issues a signed private Cloudinary download URL for the owner only', () => {
  const handlers = setup();
  const publicId = `${reportOwnerPrefix('alice')}${UUID_ALICE}.pdf`;
  const result = handlers.getDownloadUrl({ auth: { uid: 'alice' }, data: { publicId } });
  const expectedExpiresAt = Math.floor(Date.parse('2026-11-11T02:00:00Z') / 1000) + REPORT_DOWNLOAD_TTL_SECONDS;
  assert.equal(result.expiresAt, expectedExpiresAt);

  const parsed = new URL(result.url);
  assert.equal(parsed.protocol, 'https:');
  assert.equal(parsed.hostname, 'api.cloudinary.com');
  assert.equal(parsed.pathname, `/v1_1/${BASE_CONFIG.cloudName}/raw/download`);
  assert.equal(parsed.searchParams.get('public_id'), publicId);
  assert.equal(parsed.searchParams.get('type'), 'authenticated');
  assert.equal(parsed.searchParams.get('format'), 'pdf');
  assert.equal(parsed.searchParams.get('attachment'), 'true');
  assert.equal(parsed.searchParams.get('expires_at'), String(expectedExpiresAt));
  assert.equal(parsed.searchParams.get('api_key'), BASE_CONFIG.apiKey);
  assert.match(parsed.searchParams.get('signature') ?? '', /^[0-9a-f]{40,128}$/);
});

test('getDownloadUrl denies cross-user access, path traversal and non-UUID filenames', () => {
  const handlers = setup();
  const aliceId = `${reportOwnerPrefix('alice')}${UUID_ALICE}.pdf`;
  const nonV4Uuid = '11111111-2222-1333-8444-555555555555';

  assert.throws(
    () => handlers.getDownloadUrl({ auth: { uid: 'bob' }, data: { publicId: aliceId } }),
    code('permission-denied'),
  );

  for (const invalidId of [
    undefined,
    null,
    123,
    '',
    `${reportOwnerPrefix('alice')}../${UUID_ALICE}.pdf`,
    `${reportOwnerPrefix('alice')}report.pdf`,
    `${reportOwnerPrefix('alice')}${nonV4Uuid}.pdf`,
    `${reportOwnerPrefix('alice')}${UUID_ALICE}`,
    `${reportOwnerPrefix('alice')}${UUID_ALICE}.txt`,
    `${reportOwnerPrefix('alice')}${UUID_ALICE}.pdf/extra`,
  ]) {
    assert.equal(isValidReportPublicId('alice', invalidId), false);
    assert.throws(
      () => handlers.getDownloadUrl({ auth: { uid: 'alice' }, data: { publicId: invalidId } }),
      code('permission-denied'),
    );
  }
});
