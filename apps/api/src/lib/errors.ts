import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";

export class AppError extends Error {
  constructor(public status: number, public code: string, message: string, public details?: Record<string, string[]>, public retryAfterSeconds?: number) { super(message); }
}
export function notFound(req: Request, _res: Response, next: NextFunction) { next(new AppError(404, "NOT_FOUND", `No route for ${req.method} ${req.path}`)); }
export function errorHandler(error: unknown, req: Request, res: Response, _next: NextFunction) {
  void _next;
  if (error instanceof ZodError) {
    const fieldErrors: Record<string, string[]> = {};
    for (const issue of error.issues) { const key = issue.path.join(".") || "body"; (fieldErrors[key] ??= []).push(issue.message); }
    return res.status(422).json({ error: { code: "VALIDATION_ERROR", message: "Request validation failed", fieldErrors, requestId: req.requestId } });
  }
  const appError = error instanceof AppError ? error : new AppError(500, "INTERNAL_ERROR", "An unexpected error occurred");
  if (appError.retryAfterSeconds) res.setHeader("Retry-After", appError.retryAfterSeconds);
  return res.status(appError.status).json({ error: { code: appError.code, message: appError.message, ...(appError.details ? { fieldErrors: appError.details } : {}), requestId: req.requestId, ...(appError.retryAfterSeconds ? { retryAfterSeconds: appError.retryAfterSeconds } : {}) } });
}
