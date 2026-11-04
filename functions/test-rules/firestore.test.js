import { readFile } from 'node:fs/promises';
import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

// An emulator is mandatory. Do not allow this suite to target a real project.
const emulatorAddress = process.env.FIRESTORE_EMULATOR_HOST;
if (!emulatorAddress) throw new Error('Start the local Firestore emulator before npm run test:rules.');
const emulatorUrl = new URL(`http://${emulatorAddress}`);
if (!['localhost', '127.0.0.1', '[::1]'].includes(emulatorUrl.hostname) || !emulatorUrl.port) {
  throw new Error('Rules tests accept only a local emulator host and explicit port.');
}

let environment;
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-vetalife-rules',
    firestore: {
      host: emulatorUrl.hostname,
      port: Number(emulatorUrl.port),
      rules: await readFile(new URL('../../firebase/firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    for (const uid of ['alice', 'bob']) {
      await setDoc(doc(context.firestore(), 'users', uid), {
        displayName: uid,
        birthDate: '2000-02-29', weightKg: 62.5, heightCm: 170.5,
        goal: 'addVegetables', updatedAt: serverTimestamp(),
      });
    }
    await setDoc(doc(context.firestore(), '_mealAiUsage', 'alice'), {
      day: '2026-11-03', dayCount: 1, minute: '2026-11-03T12:00', minuteCount: 1,
    });
  });
});

after(async () => { if (environment) await environment.cleanup(); });

function meal(id = 'meal_1') {
  return {
    id,
    draft: {
      id, name: 'Đậu hũ và gạo lứt', mealType: 'lunch', eatenAt: '2026-11-03T05:30:00.000Z',
      ingredients: [{ name: 'Đậu hũ', amount: '', preparation: '' }], notes: '',
    },
    analysis: {
      title: 'Đối chiếu sách', summary: 'Bữa ăn có đậu hũ đã xác nhận.',
      highlights: ['Có thực phẩm từ đậu.'], improvements: ['Thử đổi loại đậu ở bữa khác.'],
      profileNote: 'Mục tiêu thêm rau.', limitations: ['Không đủ dữ liệu về khẩu phần.'],
      references: [{ id: 'beans-protein-fibre', chapterId: 'p2-dd01', title: 'Đậu', printedPage: 374, pdfPage: 376, summary: 'Nguồn sách đã đối chiếu.' }],
      healthConnections: [], mode: 'localBook',
    },
    savedAt: '2026-11-03T05:35:00.000Z', updatedAt: serverTimestamp(),
  };
}

const contextFor = (uid) => uid ? environment.authenticatedContext(uid) : environment.unauthenticatedContext();
const mealDocument = (db, uid = 'alice', id = 'meal_1') => doc(db, 'users', uid, 'meals', id);

test('owner creates, reads, lists and updates their own meal', async () => {
  const db = contextFor('alice').firestore();
  const reference = mealDocument(db);
  await assertSucceeds(setDoc(reference, meal()));
  const first = await assertSucceeds(getDoc(reference));
  assert.equal(first.data().draft.name, 'Đậu hũ và gạo lứt');
  await assertSucceeds(updateDoc(reference, { 'draft.notes': 'Có thêm rau.', updatedAt: serverTimestamp() }));
  const listed = await assertSucceeds(getDocs(collection(db, 'users', 'alice', 'meals')));
  assert.equal(listed.size, 1);
  assert.equal(listed.docs[0].data().draft.notes, 'Có thêm rau.');
});

test('repeated owner writes with the same ID update one record, not a duplicate', async () => {
  const db = contextFor('alice').firestore();
  await assertSucceeds(setDoc(mealDocument(db), meal()));
  await assertSucceeds(setDoc(mealDocument(db), { ...meal(), savedAt: '2026-11-03T05:36:00.000Z' }));
  assert.equal((await getDocs(collection(db, 'users', 'alice', 'meals'))).size, 1);
});

test('cross-user create/read/list/update are all denied', async () => {
  const owner = contextFor('alice').firestore();
  await assertSucceeds(setDoc(mealDocument(owner), meal()));
  const attacker = contextFor('bob').firestore();
  await assertFails(getDoc(mealDocument(attacker)));
  await assertFails(getDocs(collection(attacker, 'users', 'alice', 'meals')));
  await assertFails(setDoc(mealDocument(attacker, 'alice', 'meal_2'), meal('meal_2')));
  await assertFails(updateDoc(mealDocument(attacker), { 'draft.notes': 'Changed by another UID', updatedAt: serverTimestamp() }));
});

test('unauthenticated reads/list/create/update are denied', async () => {
  await assertSucceeds(setDoc(mealDocument(contextFor('alice').firestore()), meal()));
  const db = contextFor(null).firestore();
  await assertFails(getDoc(mealDocument(db)));
  await assertFails(getDocs(collection(db, 'users', 'alice', 'meals')));
  await assertFails(setDoc(mealDocument(db, 'alice', 'meal_2'), meal('meal_2')));
  await assertFails(updateDoc(mealDocument(db), { 'draft.notes': 'Anonymous edit', updatedAt: serverTimestamp() }));
});

test('owner cannot save a meal before a profile exists or delete cloud history', async () => {
  const noProfile = contextFor('new-user').firestore();
  await assertFails(setDoc(mealDocument(noProfile, 'new-user'), meal()));
  const owner = contextFor('alice').firestore();
  await assertSucceeds(setDoc(mealDocument(owner), meal()));
  await assertFails(deleteDoc(mealDocument(owner)));
});

test('record ID and nested draft ID must match the document path', async () => {
  const db = contextFor('alice').firestore();
  await assertFails(setDoc(mealDocument(db), { ...meal(), id: 'another_id' }));
  const value = meal();
  value.draft.id = 'another_id';
  await assertFails(setDoc(mealDocument(db), value));
});

test('photo fields and unknown payload keys cannot enter the meal record', async () => {
  const db = contextFor('alice').firestore();
  for (const field of ['photo', 'imageBase64', 'imageUrl', 'uid']) {
    await assertFails(setDoc(mealDocument(db), { ...meal(), [field]: 'unwanted content' }));
  }
  const draftPhoto = meal();
  draftPhoto.draft.photo = 'raw photo';
  await assertFails(setDoc(mealDocument(db), draftPhoto));
  const analysisPhoto = meal();
  analysisPhoto.analysis.photo = 'raw photo';
  await assertFails(setDoc(mealDocument(db), analysisPhoto));
});

test('oversized names and ingredient count, wrong types and forged timestamps are denied', async () => {
  const db = contextFor('alice').firestore();
  const cases = [];
  const longName = meal(); longName.draft.name = 'a'.repeat(161); cases.push(longName);
  const emptyIngredients = meal(); emptyIngredients.draft.ingredients = []; cases.push(emptyIngredients);
  const tooManyIngredients = meal(); tooManyIngredients.draft.ingredients = Array(31).fill({ name: 'Đậu', amount: '', preparation: '' }); cases.push(tooManyIngredients);
  const badMode = meal(); badMode.analysis.mode = 'pretend-ai'; cases.push(badMode);
  const wrongType = meal(); wrongType.analysis.highlights = 'not a list'; cases.push(wrongType);
  cases.push({ ...meal(), updatedAt: '2026-11-03T05:35:00Z' });
  for (const value of cases) await assertFails(setDoc(mealDocument(db), value));
});

test('AI quota documents remain server-only for every client identity', async () => {
  for (const uid of ['alice', 'bob', null]) {
    const db = contextFor(uid).firestore();
    const reference = doc(db, '_mealAiUsage', 'alice');
    await assertFails(getDoc(reference));
    await assertFails(getDocs(collection(db, '_mealAiUsage')));
    await assertFails(setDoc(reference, { dayCount: 0 }));
    await assertFails(updateDoc(reference, { dayCount: 0 }));
    await assertFails(deleteDoc(reference));
  }
});

const lessonProgress = (lessonId = 'p1-ch01') => ({
  lessonId, readAt: '2026-11-04T03:30:00.000Z', updatedAt: serverTimestamp(),
});
const progressDoc = (db, uid = 'alice', id = 'p1-ch01') => doc(db, 'users', uid, 'lessonProgress', id);

test('owner marks a lesson read, lists progress and retries without a duplicate', async () => {
  const db = contextFor('alice').firestore();
  await assertSucceeds(setDoc(progressDoc(db), lessonProgress()));
  await assertSucceeds(setDoc(progressDoc(db), lessonProgress()));
  await assertSucceeds(setDoc(progressDoc(db, 'alice', 'p2-introduction'), lessonProgress('p2-introduction')));
  const stored = await assertSucceeds(getDoc(progressDoc(db)));
  assert.equal(stored.data().lessonId, 'p1-ch01');
  const listed = await assertSucceeds(getDocs(collection(db, 'users', 'alice', 'lessonProgress')));
  assert.equal(listed.size, 2);
});

test('lesson progress isolates users, denies anonymous access and cloud deletion', async () => {
  const owner = contextFor('alice').firestore();
  await assertSucceeds(setDoc(progressDoc(owner), lessonProgress()));
  for (const uid of ['bob', null]) {
    const db = contextFor(uid).firestore();
    await assertFails(getDoc(progressDoc(db)));
    await assertFails(getDocs(collection(db, 'users', 'alice', 'lessonProgress')));
    await assertFails(setDoc(progressDoc(db), lessonProgress()));
    await assertFails(updateDoc(progressDoc(db), { readAt: '2026-11-04T04:00:00.000Z', updatedAt: serverTimestamp() }));
  }
  await assertFails(deleteDoc(progressDoc(owner)));
  const noProfile = contextFor('new-user').firestore();
  await assertFails(setDoc(progressDoc(noProfile, 'new-user'), lessonProgress()));
});

test('only all 30 known lesson IDs can be recorded, with strict identity and timestamps', async () => {
  const db = contextFor('alice').firestore();
  const ids = [
    ...Array.from({length: 15}, (_, i) => `p1-ch${String(i + 1).padStart(2, '0')}`),
    ...Array.from({length: 12}, (_, i) => `p2-dd${String(i + 1).padStart(2, '0')}`),
    'p2-introduction', 'p2-daily-dozen', 'p2-conclusion',
  ];
  for (const id of ids) await assertSucceeds(setDoc(progressDoc(db, 'alice', id), lessonProgress(id)));
  assert.equal((await getDocs(collection(db, 'users', 'alice', 'lessonProgress'))).size, 30);
  for (const id of ['p1-ch00', 'p1-ch16', 'p2-dd00', 'p2-dd13', 'p2-dd99', 'invented', 'front-preface']) {
    await assertFails(setDoc(progressDoc(db, 'alice', id), lessonProgress(id)));
  }
  for (const value of [
    {...lessonProgress(), lessonId: 'p1-ch02'},
    {...lessonProgress(), uid: 'alice'},
    {...lessonProgress(), body: 'unwanted lesson copy'},
    {...lessonProgress(), readAt: true},
    {...lessonProgress(), readAt: '2026-11-04'},
    {...lessonProgress(), readAt: '2026-11-04T03:30:00.000'},
    {...lessonProgress(), updatedAt: '2026-11-04T03:30:00.000Z'},
  ]) await assertFails(setDoc(progressDoc(db), value));
});
