const text = { type: 'string' };
const list = (items = text) => ({ type: 'array', items });
const object = (properties) => ({
  type: 'object',
  additionalProperties: false,
  properties,
  required: Object.keys(properties),
});

export const ingredientSchema = object({ name: text, amount: text, preparation: text });

export const recognitionSchema = object({
  mealName: text,
  ingredients: list(ingredientSchema),
  ocrText: text,
  warnings: list(),
});

export function analysisSchema(sourceIds, healthTopics) {
  const reference = { type: 'string', enum: sourceIds };
  return object({
    title: text,
    summary: text,
    highlights: list(),
    improvements: list(),
    profileNote: text,
    limitations: list(),
    sourceIds: list(reference),
    healthConnections: list(object({
      topic: healthTopics.length ? { type: 'string', enum: healthTopics } : text,
      explanation: text,
      referenceIds: list(reference),
    })),
  });
}
