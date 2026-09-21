import { createCipheriv, createDecipheriv, createHmac, randomBytes, timingSafeEqual } from "node:crypto";
import { getConfig } from "../config.js";
export const randomToken = (bytes = 48) => randomBytes(bytes).toString("base64url");
export const hashToken = (value: string) => createHmac("sha256", getConfig().TOKEN_HASH_SECRET).update(value).digest("hex");
export function safeEqual(a: string, b: string): boolean { const aa = Buffer.from(a); const bb = Buffer.from(b); return aa.length === bb.length && timingSafeEqual(aa, bb); }
export function encryptSecret(value: string): string {
  const key = Buffer.from(getConfig().TOTP_ENCRYPTION_KEY, "base64"); if (key.length !== 32) throw new Error("TOTP_ENCRYPTION_KEY must decode to 32 bytes");
  const iv = randomBytes(12); const cipher = createCipheriv("aes-256-gcm", key, iv); const data = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  return [iv.toString("base64url"), cipher.getAuthTag().toString("base64url"), data.toString("base64url")].join(".");
}
export function decryptSecret(value: string): string {
  const [iv, tag, data] = value.split("."); if (!iv || !tag || !data) throw new Error("Invalid encrypted secret");
  const decipher = createDecipheriv("aes-256-gcm", Buffer.from(getConfig().TOTP_ENCRYPTION_KEY, "base64"), Buffer.from(iv, "base64url"));
  decipher.setAuthTag(Buffer.from(tag, "base64url")); return Buffer.concat([decipher.update(Buffer.from(data, "base64url")), decipher.final()]).toString("utf8");
}

