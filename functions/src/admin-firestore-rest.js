import { randomUUID } from 'node:crypto';
import { AdminError } from './admin-service.js';
import { journalMeal } from './admin-journal.js';

const unavailable = () => new AdminError('unavailable', 'Dịch vụ dữ liệu quản trị chưa sẵn sàng. Vui lòng thử lại.');
const validId = (value) => typeof value === 'string' && value.length > 0 && value.length <= 128 &&
  value === value.trim() && !/[\s/\u0000-\u001f\u007f]/u.test(value);
const isObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);
const auditActions = new Set(['disable-user', 'enable-user', 'revoke-sessions', 'update-display-name']);

/** REST alternative for the loopback admin server; credentials never enter responses. */
export function createAdminFirestoreRest({ projectId, getAccessToken, fetchImpl = fetch, now = () => new Date(), createUuid = randomUUID }) {
  if (typeof projectId !== 'string' || !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(projectId) ||
      typeof getAccessToken !== 'function' || typeof fetchImpl !== 'function') {
    throw new AdminError('failed-precondition', 'Cấu hình dịch vụ dữ liệu quản trị không hợp lệ.');
  }
  const root = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
  const resourceRoot = `projects/${projectId}/databases/(default)/documents`;
  const missingDocument = Symbol('missing-document');

  function checkedUid(uid) {
    if (!validId(uid)) throw new AdminError('invalid-argument', 'UID không hợp lệ.');
    return encodeURIComponent(uid);
  }

  function timestamp() {
    const value = now();
    if (!(value instanceof Date) || !Number.isFinite(value.getTime())) throw unavailable();
    return { timestampValue: value.toISOString() };
  }

  async function request(suffix, { method = 'GET', body, allowMissing = false } = {}) {
    // Suffixes are internal literals plus encoded document IDs; no caller URL is accepted.
    try {
      const credential = await getAccessToken();
      const token = typeof credential === 'string' ? credential : credential?.access_token;
      if (typeof token !== 'string' || !token || /[\r\n]/.test(token)) throw unavailable();
      const response = await fetchImpl(root + suffix, {
        method,
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        redirect: 'error',
        signal: AbortSignal.timeout(15000),
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
      });
      if (allowMissing && response.status === 404) return missingDocument;
      if (!response.ok) throw unavailable();
      return await response.json();
    } catch {
      // Credential, fetch, response bodies and JSON parse errors can include secrets.
      throw unavailable();
    }
  }

  async function count(uid, collectionId) {
    const rows = await request(`/users/${uid}:runAggregationQuery`, {
      method: 'POST',
      body: {
        structuredAggregationQuery: {
          aggregations: [{ alias: 'count', count: {} }],
          structuredQuery: { from: [{ collectionId }] },
        },
      },
    });
    if (!Array.isArray(rows)) throw unavailable();
    const results = rows.filter((row) => row?.result !== undefined);
    if (results.length !== 1) throw unavailable();
    const value = results[0]?.result?.aggregateFields?.count?.integerValue;
    if (typeof value !== 'string' || !/^\d+$/.test(value)) throw unavailable();
    const number = Number(value);
    if (!Number.isSafeInteger(number) || number < 0) throw unavailable();
    return number;
  }

  return {
    async loadUserJournal({ uid, pageSize, afterId }) {
      const userPath = `/users/${checkedUid(uid)}`;
      const mealResource = `${resourceRoot}/users/${uid}/meals/`;
      const structuredQuery = {
        from: [{ collectionId: 'meals' }],
        orderBy: [{ field: { fieldPath: 'draft.eatenAt' }, direction: 'DESCENDING' },
          { field: { fieldPath: '__name__' }, direction: 'DESCENDING' }],
        limit: pageSize + 1,
      };
      if (afterId) {
        const cursor = await request(`${userPath}/meals/${checkedUid(afterId)}`, { allowMissing: true });
        const eatenAt = cursor?.fields?.draft?.mapValue?.fields?.eatenAt;
        if (cursor === missingDocument || typeof eatenAt?.stringValue !== 'string') {
          throw new AdminError('invalid-argument', 'Trang nhật ký không hợp lệ.');
        }
        structuredQuery.startAt = { before: false, values: [eatenAt,
          { referenceValue: `${mealResource}${afterId}` }] };
      }
      const rows = await request(`${userPath}:runQuery`, { method: 'POST', body: { structuredQuery } });
      if (!Array.isArray(rows)) throw unavailable();
      const documents = rows.filter(row => row.document).map(row => row.document);
      const meals = documents.slice(0, pageSize).map(doc => {
        if (typeof doc.name !== 'string' || !doc.name.startsWith(mealResource)) throw unavailable();
        const fields = doc.fields?.draft?.mapValue?.fields;
        return journalMeal(doc.name.split('/').at(-1), { draft: {
          name: fields?.name?.stringValue, mealType: fields?.mealType?.stringValue,
          eatenAt: fields?.eatenAt?.stringValue, notes: fields?.notes?.stringValue,
          ingredients: fields?.ingredients?.arrayValue ? fields.ingredients.arrayValue.values ?? [] : undefined,
        } });
      });
      return { meals, nextId: documents.length > pageSize ? meals.at(-1).id : null };
    },
    async loadAuditLogs({ pageSize, targetUid, afterId }) {
      const structuredQuery = {
        from: [{ collectionId: 'adminAuditLogs' }],
        orderBy: [{ field: { fieldPath: 'createdAt' }, direction: 'DESCENDING' },
          { field: { fieldPath: '__name__' }, direction: 'DESCENDING' }],
        limit: pageSize + 1,
      };
      if (targetUid) {
        checkedUid(targetUid);
        structuredQuery.where = { fieldFilter: { field: { fieldPath: 'targetUid' }, op: 'EQUAL', value: { stringValue: targetUid } } };
        structuredQuery.orderBy = [{ field: { fieldPath: '__name__' }, direction: 'ASCENDING' }];
      }
      if (afterId) {
        const cursor = await request(`/adminAuditLogs/${checkedUid(afterId)}`, { allowMissing: true });
        if (cursor === missingDocument || !cursor?.fields?.createdAt?.timestampValue ||
            (targetUid && cursor.fields.targetUid?.stringValue !== targetUid)) {
          throw new AdminError('invalid-argument', 'Trang nhật ký không hợp lệ.');
        }
        const reference = { referenceValue: `${resourceRoot}/adminAuditLogs/${afterId}` };
        structuredQuery.startAt = { before: false, values: targetUid ? [reference] : [cursor.fields.createdAt, reference] };
      }
      const rows = await request(':runQuery', { method: 'POST', body: { structuredQuery } });
      if (!Array.isArray(rows)) throw unavailable();
      const documents = rows.filter(row => row.document).map(row => row.document);
      const logs = documents.slice(0, pageSize).map(doc => {
        const fields = doc.fields;
        if (typeof doc.name !== 'string' || !doc.name.startsWith(`${resourceRoot}/adminAuditLogs/`) ||
            !['actorUid', 'targetUid', 'action', 'status'].every(key => typeof fields?.[key]?.stringValue === 'string')) throw unavailable();
        return { id: doc.name.split('/').at(-1), actorUid: fields.actorUid.stringValue,
          targetUid: fields.targetUid.stringValue, action: fields.action.stringValue, status: fields.status.stringValue,
          createdAt: fields.createdAt?.timestampValue ?? null, completedAt: fields.completedAt?.timestampValue ?? null };
      });
      return { logs, nextId: documents.length > pageSize ? logs.at(-1).id : null };
    },

    async loadProfile(uid) {
      const document = await request(`/users/${checkedUid(uid)}`, { allowMissing: true });
      if (document === missingDocument) return null;
      // Firestore can omit fields on an existing empty document.
      if (!isObject(document) || (document.fields !== undefined && !isObject(document.fields))) throw unavailable();
      const fields = document.fields ?? {};
      const profile = {};
      for (const key of ['displayName', 'birthDate', 'goal']) {
        if (typeof fields[key]?.stringValue === 'string') profile[key] = fields[key].stringValue.slice(0, 200);
      }
      for (const key of ['weightKg', 'heightCm']) {
        const field = fields[key];
        if (!isObject(field)) continue;
        let value;
        if (typeof field.integerValue === 'string' && /^-?\d+$/.test(field.integerValue)) value = Number(field.integerValue);
        else if (typeof field.doubleValue === 'number') value = field.doubleValue;
        if (Number.isFinite(value)) profile[key] = value;
      }
      return profile;
    },

    async countActivity(uid) {
      const encodedUid = checkedUid(uid);
      const [mealCount, readLessonCount] = await Promise.all([
        count(encodedUid, 'meals'), count(encodedUid, 'lessonProgress'),
      ]);
      return { mealCount, readLessonCount };
    },

    async beginAudit(entry) {
      if (!isObject(entry) || !validId(entry.actorUid) || !validId(entry.targetUid) ||
          !auditActions.has(entry.action) || entry.status !== 'attempted' ||
          Object.keys(entry).some((key) => !['actorUid', 'targetUid', 'action', 'status'].includes(key))) {
        throw new AdminError('invalid-argument', 'Thông tin ghi nhận quản trị không hợp lệ.');
      }
      const id = createUuid();
      if (typeof id !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) throw unavailable();
      const fields = Object.fromEntries(Object.entries(entry).map(([key, value]) => [key, { stringValue: value }]));
      fields.createdAt = timestamp();
      const document = await request(`/adminAuditLogs?documentId=${encodeURIComponent(id)}`, { method: 'POST', body: { fields } });
      if (document?.name !== `${resourceRoot}/adminAuditLogs/${id}`) throw unavailable();
      return id;
    },

    async finishAudit(id, result) {
      if (typeof id !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id) ||
          !isObject(result) || !['completed', 'failed'].includes(result.status) || Object.keys(result).some((key) => key !== 'status')) {
        throw new AdminError('invalid-argument', 'Thông tin ghi nhận quản trị không hợp lệ.');
      }
      await request(`/adminAuditLogs/${encodeURIComponent(id)}?updateMask.fieldPaths=status&updateMask.fieldPaths=completedAt&currentDocument.exists=true`, {
        method: 'PATCH', body: { fields: { status: { stringValue: result.status }, completedAt: timestamp() } },
      });
    },
  };
}
