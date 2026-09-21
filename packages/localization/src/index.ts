import en from "./locales/en.json" with { type: "json" };
import ha from "./locales/ha.json" with { type: "json" };
import ig from "./locales/ig.json" with { type: "json" };
import pcm from "./locales/pcm.json" with { type: "json" };
import yo from "./locales/yo.json" with { type: "json" };
export const translations = { en, pcm, ig, ha, yo } as const;
export type TranslationKey = keyof typeof en;
export function translate(locale: keyof typeof translations, key: TranslationKey): string { return translations[locale][key] ?? translations.en[key]; }

