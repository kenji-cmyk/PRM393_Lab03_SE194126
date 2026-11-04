import { MealError } from './meal-service.js';

export const DAILY_LIMIT = 40;
export const MINUTE_LIMIT = 6;

export function nextUsage(previous, now = new Date()) {
  const day = now.toISOString().slice(0, 10);
  const minute = now.toISOString().slice(0, 16);
  const dayCount = previous?.day === day && Number.isSafeInteger(previous.dayCount) ? previous.dayCount : 0;
  const minuteCount = previous?.minute === minute && Number.isSafeInteger(previous.minuteCount) ? previous.minuteCount : 0;
  if (dayCount >= DAILY_LIMIT || minuteCount >= MINUTE_LIMIT) {
    throw new MealError('resource-exhausted', 'Bạn đã dùng hết lượt AI trong khoảng thời gian này. Vui lòng thử lại sau.');
  }
  return { day, minute, dayCount: dayCount + 1, minuteCount: minuteCount + 1 };
}

export function firestoreQuota(db, now = () => new Date()) {
  return async (uid) => {
    const reference = db.collection('_mealAiUsage').doc(uid);
    await db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      transaction.set(reference, nextUsage(snapshot.exists ? snapshot.data() : undefined, now()));
    });
  };
}
