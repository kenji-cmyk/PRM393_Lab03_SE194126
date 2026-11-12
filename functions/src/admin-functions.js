import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldPath, FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { AdminError, createAdminHandlers } from './admin-service.js';
import { journalMeal } from './admin-journal.js';

if (!getApps().length) initializeApp();

function handlers() {
  const db = getFirestore();
  return createAdminHandlers({
    auth: getAuth(),
    loadUserJournal: async ({ uid, pageSize, afterId }) => {
      const collection = db.collection('users').doc(uid).collection('meals');
      let query = collection.orderBy('draft.eatenAt', 'desc').orderBy(FieldPath.documentId(), 'desc');
      if (afterId) {
        const cursor = await collection.doc(afterId).get();
        if (!cursor.exists || typeof cursor.get('draft.eatenAt') !== 'string') {
          throw new AdminError('invalid-argument', 'Trang nhật ký không hợp lệ.');
        }
        query = query.startAfter(cursor);
      }
      const snapshot = await query.limit(pageSize + 1).get();
      const meals = snapshot.docs.slice(0, pageSize).map(doc => journalMeal(doc.id, doc.data()));
      return { meals, nextId: snapshot.size > pageSize ? meals.at(-1).id : null };
    },
    loadAuditLogs: async ({ pageSize, targetUid, afterId }) => {
      const collection = db.collection('adminAuditLogs');
      let query = targetUid ? collection.where('targetUid', '==', targetUid) : collection;
      query = targetUid ? query.orderBy(FieldPath.documentId(), 'asc')
        : query.orderBy('createdAt', 'desc').orderBy(FieldPath.documentId(), 'desc');
      if (afterId) {
        const cursor = await collection.doc(afterId).get();
        if (!cursor.exists || !cursor.get('createdAt') || (targetUid && cursor.get('targetUid') !== targetUid)) {
          throw new AdminError('invalid-argument', 'Trang nhật ký không hợp lệ.');
        }
        query = query.startAfter(cursor);
      }
      const snapshot = await query.limit(pageSize + 1).get();
      const logs = snapshot.docs.slice(0, pageSize).map(doc => {
        const data = doc.data();
        return { id: doc.id, actorUid: data.actorUid, targetUid: data.targetUid,
          action: data.action, status: data.status,
          createdAt: data.createdAt?.toDate().toISOString() ?? null,
          completedAt: data.completedAt?.toDate().toISOString() ?? null };
      });
      return { logs, nextId: snapshot.size > pageSize ? logs.at(-1).id : null };
    },
    loadProfile: async (uid) => {
      const snapshot = await db.collection('users').doc(uid).get();
      if (!snapshot.exists) return null;
      const data = snapshot.data();
      // Explicit allowlist: do not expose future private fields accidentally.
      const profile = {};
      for (const key of ['displayName', 'birthDate', 'goal']) {
        if (typeof data[key] === 'string') profile[key] = data[key].slice(0, 200);
      }
      for (const key of ['weightKg', 'heightCm']) {
        if (typeof data[key] === 'number' && Number.isFinite(data[key])) profile[key] = data[key];
      }
      return profile;
    },
    countActivity: async (uid) => {
      const root = db.collection('users').doc(uid);
      const [meals, lessons] = await Promise.all([
        root.collection('meals').count().get(),
        root.collection('lessonProgress').count().get(),
      ]);
      return { mealCount: meals.data().count, readLessonCount: lessons.data().count };
    },
    beginAudit: async (entry) => {
      const record = await db.collection('adminAuditLogs').add({ ...entry, createdAt: FieldValue.serverTimestamp() });
      return record.id;
    },
    finishAudit: (id, result) => db.collection('adminAuditLogs').doc(id).update({ ...result, completedAt: FieldValue.serverTimestamp() }),
  });
}

const options = { region: 'asia-southeast1', timeoutSeconds: 30, memory: '256MiB', maxInstances: 2, concurrency: 8 };

async function call(method, request) {
  try { return await handlers()[method](request); }
  catch (error) {
    if (error instanceof AdminError) throw new HttpsError(error.code, error.message);
    if (error.code === 'auth/user-not-found') throw new HttpsError('not-found', 'Không tìm thấy người dùng.');
    if (error.code === 'auth/invalid-page-token') throw new HttpsError('invalid-argument', 'Trang tiếp theo không hợp lệ.');
    // Provider errors may contain email, UID or configuration; never return them.
    throw new HttpsError('unavailable', 'Dịch vụ quản trị chưa sẵn sàng. Vui lòng thử lại.');
  }
}

export const adminListUsers = onCall(options, (request) => call('listUsers', request));
export const adminGetUser = onCall(options, (request) => call('getUser', request));
export const adminSetUserDisabled = onCall(options, (request) => call('setUserDisabled', request));
export const adminRevokeUserSessions = onCall(options, (request) => call('revokeUserSessions', request));
export const adminUpdateDisplayName = onCall(options, (request) => call('updateDisplayName', request));
export const adminListAuditLogs = onCall(options, (request) => call('listAuditLogs', request));
export const adminGetUserJournal = onCall(options, (request) => call('getUserJournal', request));
export const adminGetStatistics = onCall(options, (request) => call('getStatistics', request));
