import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { AdminError, createAdminHandlers } from './admin-service.js';

if (!getApps().length) initializeApp();

function handlers() {
  const db = getFirestore();
  return createAdminHandlers({
    auth: getAuth(),
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
