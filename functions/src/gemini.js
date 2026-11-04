import { GoogleGenAI } from '@google/genai';
import { MealError } from './meal-service.js';

export const DEFAULT_MODEL = 'gemini-3.8-flash';

export function createGeminiGenerate({ apiKey, model = DEFAULT_MODEL, client } = {}) {
  if (!client && (typeof apiKey !== 'string' || !apiKey.trim())) {
    throw new MealError('failed-precondition', 'Dịch vụ AI chưa được cấu hình. Vui lòng thử lại sau.');
  }
  const ai = client ?? new GoogleGenAI({ apiKey });
  return async ({ contents, systemInstruction, responseJsonSchema, signal, timeoutMs }) => {
    const response = await ai.models.generateContent({
      model,
      contents,
      config: {
        systemInstruction,
        responseMimeType: 'application/json',
        responseJsonSchema,
        abortSignal: signal,
        httpOptions: { timeout: timeoutMs },
        maxOutputTokens: 4096,
      },
    });
    return response.text;
  };
}
