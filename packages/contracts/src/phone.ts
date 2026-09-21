import { parsePhoneNumberFromString } from "libphonenumber-js";

export function normalizeNigerianPhone(input: string): string {
  const cleaned = input.trim().replace(/[\s()-]/g, "");
  const candidate = cleaned.startsWith("0") ? `+234${cleaned.slice(1)}` : cleaned;
  const parsed = parsePhoneNumberFromString(candidate, "NG");
  if (!parsed?.isValid() || parsed.country !== "NG" || parsed.getType() === "FIXED_LINE") {
    throw new Error("INVALID_NIGERIAN_PHONE");
  }
  return parsed.number;
}

