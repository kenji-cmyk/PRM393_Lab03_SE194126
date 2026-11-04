import test from 'node:test';
import assert from 'node:assert/strict';
import { createGeminiGenerate, DEFAULT_MODEL } from '../src/gemini.js';

test('Gemini adapter configures structured output, abort signal, timeout and configured model', async () => {
  let call;
  const generate = createGeminiGenerate({ client: { models: { generateContent: async (request) => { call = request; return { text: '{"ok":true}' }; } } } });
  const controller = new AbortController();
  const result = await generate({ contents: 'content', systemInstruction: 'system', responseJsonSchema: { type: 'object' }, signal: controller.signal, timeoutMs: 1000 });
  assert.equal(result, '{"ok":true}');
  assert.equal(call.model, DEFAULT_MODEL);
  assert.equal(call.config.abortSignal, controller.signal);
  assert.equal(call.config.httpOptions.timeout, 1000);
  assert.equal(call.config.responseMimeType, 'application/json');
  assert.deepEqual(call.config.responseJsonSchema, { type: 'object' });
  assert.equal(call.config.maxOutputTokens, 4096);
});

test('missing provider secret fails explicitly and never exposes a key', () => {
  assert.throws(() => createGeminiGenerate({ apiKey: '' }), (error) => error.code === 'failed-precondition');
});
