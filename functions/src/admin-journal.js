import { AdminError } from './admin-service.js';

/** Only journal fields intended for the administrator; never return raw analysis/photo data. */
export function journalMeal(id, data) {
  const draft = data?.draft;
  if (!draft || typeof draft.name !== 'string' || typeof draft.eatenAt !== 'string' ||
      !Number.isFinite(Date.parse(draft.eatenAt)) || !Array.isArray(draft.ingredients) ||
      !['breakfast', 'lunch', 'dinner', 'snack'].includes(draft.mealType)) {
    throw new AdminError('unavailable', 'Dữ liệu nhật ký chưa hợp lệ.');
  }
  return { id, name: draft.name.slice(0, 160), mealType: draft.mealType,
    eatenAt: draft.eatenAt, notes: typeof draft.notes === 'string' ? draft.notes.slice(0, 1000) : '',
    ingredientCount: draft.ingredients.length };
}
