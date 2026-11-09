import { readFile } from 'node:fs/promises';
import { before, beforeEach, after, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getMetadata, deleteObject, updateMetadata } from 'firebase/storage';

const address = process.env.FIREBASE_STORAGE_EMULATOR_HOST;
if (!address) throw new Error('Start the local Storage emulator before running this suite.');
const emulator = new URL(`http://${address}`);
if (!['localhost', '127.0.0.1', '[::1]'].includes(emulator.hostname) || !emulator.port) {
  throw new Error('Storage rules tests require a local emulator and explicit port.');
}
let environment;
let caseId = Date.now();
let path;
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-vetalife-rules',
    storage: {
      host: emulator.hostname,
      port: Number(emulator.port),
      rules: await readFile(new URL('../../firebase/storage.rules', import.meta.url), 'utf8'),
    },
  });
});
beforeEach(async () => {
  await environment.clearStorage();
  // Unique object names also isolate runtimes that cache deleted generations.
  path = `reports/alice/${++caseId}-0123456789abcdef01234567.pdf`;
});
after(async () => { if (environment) await environment.cleanup(); });
const pdf = new TextEncoder().encode('%PDF-1.7\nsynthetic-test');
const file = (uid, location = path) => ref(
  (uid ? environment.authenticatedContext(uid) : environment.unauthenticatedContext()).storage(), location,
);

test('owner uploads, reads metadata and deletes a PDF report', async () => {
  const report = file('alice');
  await assertSucceeds(uploadBytes(report, pdf, { contentType: 'application/pdf' }));
  await assertSucceeds(getMetadata(report));
  await assertSucceeds(deleteObject(report));
});
test('cross-user and anonymous upload, read and deletion are denied', async () => {
  await uploadBytes(file('alice'), pdf, { contentType: 'application/pdf' });
  for (const uid of ['bob', null]) {
    await assertFails(getMetadata(file(uid)));
    await assertFails(deleteObject(file(uid)));
    await assertFails(uploadBytes(file(uid, 'reports/alice/124-0123456789abcdef01234567.pdf'), pdf, { contentType: 'application/pdf' }));
  }
});
test('owner cannot overwrite reports or modify existing metadata', async () => {
  const report = file('alice');
  await uploadBytes(report, pdf, { contentType: 'application/pdf' });
  await assertFails(uploadBytes(report, pdf, { contentType: 'application/pdf' }));
  await assertFails(updateMetadata(report, { customMetadata: { firebaseStorageDownloadTokens: 'public-token' } }));
});
test('wrong MIME type, invalid filename, empty and oversized reports are denied', async () => {
  await assertFails(uploadBytes(file('alice'), pdf, { contentType: 'text/plain' }));
  await assertFails(uploadBytes(file('alice', 'reports/alice/report.pdf'), pdf, { contentType: 'application/pdf' }));
  await assertFails(uploadBytes(file('alice'), new Uint8Array(), { contentType: 'application/pdf' }));
  await assertFails(uploadBytes(file('alice'), new Uint8Array(10 * 1024 * 1024 + 1), { contentType: 'application/pdf' }));
});
