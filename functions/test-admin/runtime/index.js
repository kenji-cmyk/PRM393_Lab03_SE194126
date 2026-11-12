// Emulator-only entry: load real admin endpoints without unrelated AI/report
// secrets or required Cloudinary parameters from the application's main entry.
export {
  adminListUsers,
  adminGetUser,
  adminSetUserDisabled,
  adminRevokeUserSessions,
  adminUpdateDisplayName,
  adminListAuditLogs,
  adminGetUserJournal,
  adminGetStatistics,
} from '../../src/admin-functions.js';
