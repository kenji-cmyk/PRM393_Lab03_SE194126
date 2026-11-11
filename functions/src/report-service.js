import { randomUUID } from 'node:crypto';
import { v2 as cloudinary } from 'cloudinary';

export const MAX_REPORT_BYTES = 10 * 1024 * 1024;
export const REPORT_DOWNLOAD_TTL_SECONDS = 10 * 60;
const UUID_V4_PDF_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.pdf$/i;

export class ReportError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'ReportError';
    this.code = code;
  }
}

export function requireReportUser(request) {
  const uid = request?.auth?.uid;
  if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/')) {
    throw new ReportError('unauthenticated', 'Cần đăng nhập để truy cập báo cáo.');
  }
  return uid;
}

export function reportOwnerPrefix(uid) {
  return `u_${Buffer.from(uid, 'utf8').toString('base64url')}/reports/`;
}

export function isValidReportPublicId(uid, publicId) {
  if (typeof publicId !== 'string') return false;
  const prefix = reportOwnerPrefix(uid);
  return publicId.startsWith(prefix) && UUID_V4_PDF_PATTERN.test(publicId.slice(prefix.length));
}

export function createReportHandlers({
  getConfig,
  now = () => new Date(),
  createUuid = randomUUID,
  signRequest = (params, secret) => cloudinary.utils.api_sign_request(params, secret),
  privateDownloadUrl = (publicId, format, options) => cloudinary.utils.private_download_url(publicId, format, options),
}) {
  function requireConfig({ requirePreset = false } = {}) {
    const config = getConfig?.() ?? {};
    const cloudName = typeof config.cloudName === 'string' ? config.cloudName.trim() : '';
    const apiKey = typeof config.apiKey === 'string' ? config.apiKey.trim() : '';
    const apiSecret = typeof config.apiSecret === 'string' ? config.apiSecret.trim() : '';
    const uploadPreset = typeof config.uploadPreset === 'string' ? config.uploadPreset.trim() : '';
    if (!cloudName || !apiKey || !apiSecret) {
      throw new ReportError('failed-precondition', 'Dịch vụ lưu báo cáo chưa được cấu hình.');
    }
    if (requirePreset && !uploadPreset) {
      throw new ReportError('failed-precondition', 'Upload preset cho báo cáo chưa được cấu hình.');
    }
    return { cloudName, apiKey, apiSecret, uploadPreset };
  }

  return {
    createUploadSignature(request) {
      const uid = requireReportUser(request);
      const { cloudName, apiKey, apiSecret, uploadPreset } = requireConfig({ requirePreset: true });
      const publicId = `${reportOwnerPrefix(uid)}${createUuid()}.pdf`;
      const timestamp = Math.floor(now().getTime() / 1000);
      const signedParams = {
        public_id: publicId,
        timestamp,
        type: 'authenticated',
        upload_preset: uploadPreset,
        overwrite: false,
      };
      const signature = signRequest(signedParams, apiSecret);

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
    },

    getDownloadUrl(request) {
      const uid = requireReportUser(request);
      const publicId = request?.data?.publicId;
      if (!isValidReportPublicId(uid, publicId)) {
        throw new ReportError('permission-denied', 'Báo cáo không thuộc tài khoản hiện tại.');
      }

      const { cloudName, apiKey, apiSecret } = requireConfig();
      const expiresAt = Math.floor(now().getTime() / 1000) + REPORT_DOWNLOAD_TTL_SECONDS;
      const url = privateDownloadUrl(publicId, 'pdf', {
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        resource_type: 'raw',
        type: 'authenticated',
        expires_at: expiresAt,
        attachment: true,
      });
      return { url, expiresAt };
    },
  };
}

