import type { AccessClaims } from "../lib/tokens.js";
declare global {
  namespace Express {
    interface Request { requestId: string; auth?: AccessClaims; stepUpVerified?: boolean }
  }
}
export {};

