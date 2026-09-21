import { createHash } from "node:crypto";
import type { Request } from "express";
import { prisma } from "@leetlogic/database";
import { AppError } from "../lib/errors.js";

const allowedScopes = new Set(["payment", "order", "inventory-reservation", "shipment"]);
export const requestFingerprint = (body: unknown) => createHash("sha256").update(JSON.stringify(body ?? null)).digest("hex");

export async function beginIdempotentMutation(req: Request, scope: string) {
  if (!allowedScopes.has(scope)) throw new AppError(500, "IDEMPOTENCY_SCOPE_INVALID", "Invalid mutation scope");
  const value = req.header("Idempotency-Key");
  if (!value || value.length > 128) throw new AppError(400, "IDEMPOTENCY_KEY_REQUIRED", "A valid Idempotency-Key header is required");
  const requestHash = requestFingerprint(req.body);
  const existing = await prisma.idempotencyRecord.findUnique({ where: { scope_idempotencyKey: { scope, idempotencyKey: value } } });
  if (existing && existing.requestHash !== requestHash) throw new AppError(409, "IDEMPOTENCY_KEY_REUSED", "This idempotency key was used with a different request");
  if (existing?.completedAt) return { replay: true as const, status: existing.responseStatus!, body: existing.responseBody };
  if (existing) throw new AppError(409, "REQUEST_IN_PROGRESS", "A request with this idempotency key is still processing", undefined, 2);
  const record = await prisma.idempotencyRecord.create({ data: { scope, idempotencyKey: value, requestHash, expiresAt: new Date(Date.now() + 86_400_000) } });
  return { replay: false as const, recordId: record.id };
}

export async function completeIdempotentMutation(recordId: string, status: number, body: object, resourceId?: string) {
  await prisma.idempotencyRecord.update({ where: { id: recordId }, data: { responseStatus: status, responseBody: body, resourceId, completedAt: new Date() } });
}
