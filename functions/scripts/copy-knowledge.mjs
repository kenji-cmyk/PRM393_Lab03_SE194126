import { mkdir, readFile, writeFile } from 'node:fs/promises';

const source = new URL('../../assets/content/meal-knowledge.json', import.meta.url);
const content = await readFile(source, 'utf8');
const corpus = JSON.parse(content);
if (corpus.schemaVersion !== 1 || !Array.isArray(corpus.entries) || !corpus.entries.length) {
  throw new Error('The verified meal knowledge corpus is missing or invalid.');
}
await mkdir(new URL('../data/', import.meta.url), { recursive: true });
await writeFile(new URL('../data/meal-knowledge.json', import.meta.url), content, 'utf8');
console.log(`Copied ${corpus.entries.length} verified book records into the Functions bundle.`);
