import type { NextFunction, Request, Response } from "express";
import { AppError } from "../lib/errors.js";
import { verifyAccessToken } from "../lib/tokens.js";
export const requireAuth = (subject: "customer" | "admin") => (req: Request, _res: Response, next: NextFunction) => {
  const [kind, token] = req.headers.authorization?.split(" ") ?? [];
  if (kind !== "Bearer" || !token) return next(new AppError(401, "AUTH_REQUIRED", "Authentication is required"));
  try { req.auth = verifyAccessToken(token, subject); next(); } catch (error) { next(error); }
};
export const requirePermission = (permission: string) => (req: Request, _res: Response, next: NextFunction) => {
  if (!req.auth?.permissions?.includes(permission)) return next(new AppError(403, "FORBIDDEN", "You do not have permission for this action")); next();
};
export const requireRecentStepUp = (req: Request, _res: Response, next: NextFunction) => {
  const ageSeconds = req.auth?.stepUpAt ? Math.floor(Date.now() / 1000) - req.auth.stepUpAt : Number.POSITIVE_INFINITY;
  if (ageSeconds > 300) return next(new AppError(403, "STEP_UP_REQUIRED", "A recent authenticator confirmation is required"));
  next();
};
