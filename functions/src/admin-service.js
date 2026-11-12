/** Admin operations have no client-writable source of authorization. */
export class AdminError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

const fail = (code, message) => { throw new AdminError(code, message); };
const validUid = (uid) => typeof uid === 'string' && uid.length > 0 &&
  uid.length <= 128 && uid === uid.trim() && !/[\s/\u0000-\u001f\u007f]/u.test(uid);
const objectData = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

function payload(request, allowed) {
  const data = request.data ?? {};
  if (!objectData(data) || Object.keys(data).some((key) => !allowed.includes(key))) {
    fail('invalid-argument', 'Dữ liệu quản trị không hợp lệ.');
  }
  return data;
}

function uidFrom(data) {
  if (!validUid(data.uid)) fail('invalid-argument', 'UID không hợp lệ.');
  return data.uid;
}

export function adminUserSummary(user) {
  return {
    uid: user.uid,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoUrl: user.photoURL ?? null,
    disabled: user.disabled === true,
    emailVerified: user.emailVerified === true,
    isAdmin: user.customClaims?.admin === true,
    createdAt: user.metadata?.creationTime ?? null,
    lastSignInAt: user.metadata?.lastSignInTime ?? null,
  };
}

/** Dependencies use Admin SDK adapters in admin-functions.js and fakes in tests. */
export function createAdminHandlers({ auth, loadProfile, countActivity, beginAudit, finishAudit }) {
  async function authorize(request) {
    if (!validUid(request.auth?.uid)) fail('unauthenticated', 'Vui lòng đăng nhập quản trị.');
    let caller;
    try { caller = await auth.getUser(request.auth.uid); }
    catch (error) {
      if (error.code === 'auth/user-not-found') fail('unauthenticated', 'Phiên đăng nhập không còn hợp lệ.');
      throw error;
    }
    if (caller.disabled || caller.customClaims?.admin !== true) {
      fail('permission-denied', 'Tài khoản không có quyền quản trị.');
    }
    const authTime = request.auth.token?.auth_time;
    const validAfter = caller.tokensValidAfterTime ? Date.parse(caller.tokensValidAfterTime) / 1000 : 0;
    if (!Number.isFinite(authTime) || authTime <= 0 || !Number.isFinite(validAfter) || authTime < validAfter) {
      fail('unauthenticated', 'Phiên quản trị đã hết hiệu lực. Vui lòng đăng nhập lại.');
    }
    return caller.uid;
  }

  async function findUser(uid) {
    try { return await auth.getUser(uid); }
    catch (error) {
      if (error.code === 'auth/user-not-found') fail('not-found', 'Không tìm thấy người dùng.');
      throw error;
    }
  }

  async function mutableTarget(actorUid, uid) {
    if (actorUid === uid) fail('failed-precondition', 'Không thể thực hiện thao tác này trên chính tài khoản quản trị.');
    const target = await findUser(uid);
    if (target.customClaims?.admin === true) {
      fail('failed-precondition', 'Tài khoản quản trị chỉ được quản lý bằng công cụ cấp quyền tin cậy.');
    }
    return target;
  }

  async function mutate(actorUid, uid, action, operation, result) {
    // No Auth mutation occurs unless its attempted action has a durable audit.
    const auditId = await beginAudit({ actorUid, targetUid: uid, action, status: 'attempted' });
    try {
      await operation();
    } catch (error) {
      try { await finishAudit(auditId, { status: 'failed' }); } catch { /* Initial audit remains. */ }
      throw error;
    }
    try {
      await finishAudit(auditId, { status: 'completed' });
      return result;
    } catch {
      // The action already succeeded. Never invite a retry by returning a failure.
      return { ...result, auditWarning: true };
    }
  }

  return {
    async listUsers(request) {
      await authorize(request);
      const data = payload(request, ['pageSize', 'pageToken', 'query']);
      const pageSize = data.pageSize ?? 25;
      if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 100) fail('invalid-argument', 'Số lượng người dùng mỗi trang phải từ 1 đến 100.');
      if (data.pageToken !== undefined && (typeof data.pageToken !== 'string' || !data.pageToken || data.pageToken.length > 2048)) fail('invalid-argument', 'Trang tiếp theo không hợp lệ.');
      if (data.query !== undefined && (typeof data.query !== 'string' || !data.query.trim() || data.query.length > 320 || data.query !== data.query.trim())) fail('invalid-argument', 'Nhập email hoặc UID chính xác.');
      if (data.query && data.pageToken) fail('invalid-argument', 'Không dùng phân trang cùng tìm kiếm.');
      if (data.query) {
        let user;
        try {
          if (data.query.includes('@')) user = await auth.getUserByEmail(data.query);
          else {
            if (!validUid(data.query)) fail('invalid-argument', 'UID không hợp lệ.');
            user = await auth.getUser(data.query);
          }
        } catch (error) {
          if (error.code === 'auth/user-not-found') return { users: [], nextPageToken: null };
          if (error.code === 'auth/invalid-email') fail('invalid-argument', 'Email không hợp lệ.');
          throw error;
        }
        return { users: [adminUserSummary(user)], nextPageToken: null };
      }
      const result = await auth.listUsers(pageSize, data.pageToken);
      return { users: result.users.map(adminUserSummary), nextPageToken: result.pageToken ?? null };
    },

    async getUser(request) {
      await authorize(request);
      const uid = uidFrom(payload(request, ['uid']));
      const user = await findUser(uid);
      const [profile, activity] = await Promise.all([loadProfile(uid), countActivity(uid)]);
      return { user: adminUserSummary(user), profile, activity };
    },

    async setUserDisabled(request) {
      const actorUid = await authorize(request);
      const data = payload(request, ['uid', 'disabled']);
      const uid = uidFrom(data);
      if (typeof data.disabled !== 'boolean') fail('invalid-argument', 'Trạng thái khóa tài khoản không hợp lệ.');
      await mutableTarget(actorUid, uid);
      return mutate(actorUid, uid, data.disabled ? 'disable-user' : 'enable-user',
        () => auth.updateUser(uid, { disabled: data.disabled }), { uid, disabled: data.disabled });
    },

    async revokeUserSessions(request) {
      const actorUid = await authorize(request);
      const uid = uidFrom(payload(request, ['uid']));
      await mutableTarget(actorUid, uid);
      return mutate(actorUid, uid, 'revoke-sessions', () => auth.revokeRefreshTokens(uid), { uid, revoked: true });
    },
  };
}
