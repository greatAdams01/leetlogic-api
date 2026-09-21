import { createHmac, randomInt } from "node:crypto";
import { prisma, type OtpPurpose, type OtpProvider as DbProvider } from "@leetlogic/database";
import { redis } from "../lib/redis.js";
import { getConfig } from "../config.js";
import { AppError } from "../lib/errors.js";
import { otpProviders } from "../providers/otp.js";

const TTL = 300; const RESEND = 60; const MAX_ATTEMPTS = 5;
const key = (purpose: OtpPurpose, phone: string, device: string) => `otp:${purpose}:${phone}:${device}`;
const hash = (value: string) => createHmac("sha256", getConfig().TOKEN_HASH_SECRET).update(value).digest("hex");
const mask = (phone: string) => `${phone.slice(0, 6)}*****${phone.slice(-2)}`;

export async function requestOtp(input: { purpose: OtpPurpose; phone: string; deviceId: string; ip?: string; requestId: string }) {
  const client = redis(); const challengeKey = key(input.purpose, input.phone, input.deviceId);
  const existing = await client.ttl(challengeKey); if (existing > TTL - RESEND) throw new AppError(429, "OTP_RESEND_TOO_SOON", "Please wait before requesting another code", undefined, existing - (TTL - RESEND));
  const phoneCount = await client.incr(`rate:otp:phone:${input.phone}`); if (phoneCount === 1) await client.expire(`rate:otp:phone:${input.phone}`, 3600);
  const ipCount = await client.incr(`rate:otp:ip:${input.ip ?? "unknown"}`); if (ipCount === 1) await client.expire(`rate:otp:ip:${input.ip ?? "unknown"}`, 3600);
  if (phoneCount > 8 || ipCount > 30) throw new AppError(429, "OTP_RATE_LIMITED", "Too many requests", undefined, 3600);
  const code = String(randomInt(0, 1_000_000)).padStart(6, "0");
  let used: DbProvider | undefined; let lastError: unknown;
  for (const provider of otpProviders()) { try { await provider.send(input.phone, code); used = provider.name; break; } catch (error) { lastError = error; } }
  if (!used) throw new AppError(503, "OTP_DELIVERY_FAILED", "Verification code could not be delivered");
  await client.hset(challengeKey, { hash: hash(code), attempts: "0", provider: used }); await client.expire(challengeKey, TTL);
  await prisma.otpEvent.create({ data: { provider: used, purpose: input.purpose, maskedDestination: mask(input.phone), outcome: "SENT", ipAddress: input.ip, requestId: input.requestId } });
  return { expiresInSeconds: TTL, resendAfterSeconds: RESEND, provider: used, debugError: lastError instanceof Error ? lastError.message : undefined };
}

export async function verifyOtp(input: { purpose: OtpPurpose; phone: string; deviceId: string; code: string; ip?: string; requestId: string }) {
  const client = redis(); const challengeKey = key(input.purpose, input.phone, input.deviceId); const data = await client.hgetall(challengeKey);
  if (!data.hash) throw new AppError(400, "OTP_EXPIRED", "The code is invalid or expired");
  const attempts = Number(data.attempts ?? 0) + 1; await client.hset(challengeKey, "attempts", attempts);
  if (attempts > MAX_ATTEMPTS) { await client.del(challengeKey); throw new AppError(429, "OTP_ATTEMPTS_EXCEEDED", "Too many incorrect attempts"); }
  if (hash(input.code) !== data.hash) throw new AppError(400, "OTP_INVALID", "The code is invalid or expired");
  await client.del(challengeKey);
  await prisma.otpEvent.create({ data: { provider: (data.provider as DbProvider | undefined) ?? "CONSOLE", purpose: input.purpose, maskedDestination: mask(input.phone), outcome: "VERIFIED", attempts, ipAddress: input.ip, requestId: input.requestId } });
}
