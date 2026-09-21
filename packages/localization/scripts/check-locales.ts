import { translations } from "../src/index.js";
const base = new Set(Object.keys(translations.en));
const failures: string[] = [];
for (const [locale, messages] of Object.entries(translations)) {
  const keys = new Set(Object.keys(messages));
  for (const key of base) if (!keys.has(key)) failures.push(`${locale}: missing ${key}`);
  for (const key of keys) if (!base.has(key)) failures.push(`${locale}: unexpected ${key}`);
  for (const [key, value] of Object.entries(messages)) if (!value.trim()) failures.push(`${locale}: empty ${key}`);
}
if (failures.length) { console.error(failures.join("\n")); process.exit(1); }
console.log(`Validated ${Object.keys(translations).length} locale bundles with ${base.size} keys.`);

