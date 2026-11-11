import { readFileSync } from 'node:fs';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { defineSecret, defineString } from 'firebase-functions/params';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { createGeminiGenerate, DEFAULT_MODEL } from './gemini.js';
import { createMealHandlers, MealError } from './meal-service.js';
import { firestoreQuota } from './quota.js';
import { createReportHandlers, ReportError } from './report-service.js';

if (!getApps().length) initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const geminiModel = defineString('GEMINI_MODEL', { default: DEFAULT_MODEL });
const cloudinaryApiSecret = defineSecret('CLOUDINARY_API_SECRET');
const cloudinaryCloudName = defineString('CLOUDINARY_CLOUD_NAME');
const cloudinaryApiKey = defineString('CLOUDINARY_API_KEY');
const cloudinaryReportUploadPreset = defineString('CLOUDINARY_REPORT_UPLOAD_PRESET');
let cachedCorpus;

function loadCorpus() {
  if (cachedCorpus) return cachedCorpus;
  const corpus = JSON.parse(readFileSync(new URL('../data/meal-knowledge.json', import.meta.url), 'utf8'));
  if (corpus.schemaVersion !== 1 || !Array.isArray(corpus.entries) || !corpus.entries.length) {
    throw new Error('Run npm run build to bundle the verified knowledge corpus.');
  }
  cachedCorpus = corpus.entries;
  return cachedCorpus;
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
    entries: loadCorpus(),
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

const reportOptions = {
  ...options,
  secrets: [cloudinaryApiSecret],
};

function reportHandlers() {
  return createReportHandlers({
    getConfig: () => ({
      cloudName: cloudinaryCloudName.value(),
      apiKey: cloudinaryApiKey.value(),
      apiSecret: cloudinaryApiSecret.value(),
      uploadPreset: cloudinaryReportUploadPreset.value(),
    }),
  });
}

function safeReportCall(method, request) {
  try {
    return reportHandlers()[method](request);
  } catch (error) {
    if (error instanceof ReportError) throw new HttpsError(error.code, error.message);
    // Never leak Cloudinary secrets or signed URLs in unhandled errors.
    throw new HttpsError('unavailable', 'Chưa kết nối được dịch vụ lưu báo cáo. Vui lòng thử lại sau.');
  }
}

export const createReportUploadSignature = onCall(
  reportOptions,
  (request) => safeReportCall('createUploadSignature', request),
);

export const getReportDownloadUrl = onCall(
  reportOptions,
  (request) => safeReportCall('getDownloadUrl', request),
);
