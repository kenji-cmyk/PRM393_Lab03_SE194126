import { readFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { v2 as cloudinary } from 'cloudinary';
import { createGeminiGenerate, DEFAULT_MODEL } from './gemini.js';
import { createMealHandlers, MealError } from './meal-service.js';
import { firestoreQuota } from './quota.js';

if (!getApps().length) initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const geminiModel = defineString('GEMINI_MODEL', { default: DEFAULT_MODEL });
const cloudinaryApiSecret = defineSecret('CLOUDINARY_API_SECRET');
const cloudinaryCloudName = defineString('CLOUDINARY_CLOUD_NAME');
const cloudinaryApiKey = defineString('CLOUDINARY_API_KEY');
const cloudinaryReportUploadPreset = defineString('CLOUDINARY_REPORT_UPLOAD_PRESET');
const MAX_REPORT_BYTES = 10 * 1024 * 1024;
const REPORT_DOWNLOAD_TTL_SECONDS = 10 * 60;
const corpus = JSON.parse(readFileSync(new URL('../data/meal-knowledge.json', import.meta.url), 'utf8'));
if (corpus.schemaVersion !== 1 || !Array.isArray(corpus.entries) || !corpus.entries.length) {
  throw new Error('Run npm run build to bundle the verified knowledge corpus.');
}

const options = {
  region: 'asia-southeast1',
  secrets: [geminiApiKey],
  timeoutSeconds: 60,
  memory: '512MiB',
  maxInstances: 2,
  concurrency: 8,
  // Authentication is required below. App Check can be enabled after the
  // Flutter clients have been registered with an appropriate provider.
  enforceAppCheck: false,
};

function service() {
  const db = getFirestore();
  return createMealHandlers({
    generate: async (request) => createGeminiGenerate({
      apiKey: geminiApiKey.value(),
      model: geminiModel.value(),
    })(request),
    loadProfile: async (uid) => {
      const profile = await db.collection('users').doc(uid).get();
      return profile.exists ? profile.data() : null;
    },
    consumeQuota: firestoreQuota(db),
    entries: corpus.entries,
  });
}

async function safeCall(method, request) {
  try {
    return await service()[method](request);
  } catch (error) {
    if (error instanceof MealError) throw new HttpsError(error.code, error.message);
    // Do not log image/profile/provider payloads, API keys, or returned text.
    throw new HttpsError('unavailable', 'Chưa kết nối được dịch vụ AI. Vui lòng thử lại sau.');
  }
}

export const recognizeMeal = onCall(options, (request) => safeCall('recognize', request));
export const analyzeMeal = onCall(options, (request) => safeCall('analyze', request));

function requireReportUser(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Cần đăng nhập để truy cập báo cáo.');
  return uid;
}

function reportOwnerPrefix(uid) {
  return `u_${Buffer.from(uid, 'utf8').toString('base64url')}/reports/`;
}

function configureCloudinary() {
  const cloudName = cloudinaryCloudName.value();
  const apiKey = cloudinaryApiKey.value();
  const apiSecret = cloudinaryApiSecret.value();
  if (!cloudName || !apiKey || !apiSecret) {
    throw new HttpsError('failed-precondition', 'Dịch vụ lưu báo cáo chưa được cấu hình.');
  }
  cloudinary.config({ cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret });
  return { cloudName, apiKey, apiSecret };
}

const reportOptions = {
  ...options,
  secrets: [cloudinaryApiSecret],
};

export const createReportUploadSignature = onCall(reportOptions, (request) => {
  const uid = requireReportUser(request);
  const { cloudName, apiKey, apiSecret } = configureCloudinary();
  const uploadPreset = cloudinaryReportUploadPreset.value();
  if (!uploadPreset) {
    throw new HttpsError('failed-precondition', 'Upload preset cho báo cáo chưa được cấu hình.');
  }

  const publicId = `${reportOwnerPrefix(uid)}${randomUUID()}.pdf`;
  const timestamp = Math.floor(Date.now() / 1000);
  const signedParams = {
    public_id: publicId,
    timestamp,
    type: 'authenticated',
    upload_preset: uploadPreset,
    overwrite: false,
  };
  const signature = cloudinary.utils.api_sign_request(signedParams, apiSecret);

  return {
    cloudName,
    apiKey,
    timestamp,
    signature,
    publicId,
    resourceType: 'raw',
    deliveryType: 'authenticated',
    uploadPreset,
    maxBytes: MAX_REPORT_BYTES,
  };
});

export const getReportDownloadUrl = onCall(reportOptions, (request) => {
  const uid = requireReportUser(request);
  const publicId = request.data?.publicId;
  const prefix = reportOwnerPrefix(uid);
  const filenamePattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.pdf$/i;
  if (typeof publicId !== 'string' || !publicId.startsWith(prefix) ||
      !filenamePattern.test(publicId.slice(prefix.length))) {
    throw new HttpsError('permission-denied', 'Báo cáo không thuộc tài khoản hiện tại.');
  }

  const { cloudName, apiKey, apiSecret } = configureCloudinary();
  const expiresAt = Math.floor(Date.now() / 1000) + REPORT_DOWNLOAD_TTL_SECONDS;
  const url = cloudinary.utils.private_download_url(publicId, 'pdf', {
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
    resource_type: 'raw',
    type: 'authenticated',
    expires_at: expiresAt,
    attachment: true,
  });
  return { url, expiresAt };
});
