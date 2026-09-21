import crypto from "node:crypto";
import cors from "cors";
import express, { type Express, type Request } from "express";
import helmet from "helmet";
import { pinoHttp } from "pino-http";
import swaggerUi from "swagger-ui-express";
import { authRouter } from "./routes/auth.js";
import { meRouter } from "./routes/me.js";
import { verificationRouter } from "./routes/verification.js";
import { adminAuthRouter } from "./routes/admin-auth.js";
import { adminRouter } from "./routes/admin.js";
import { errorHandler, notFound } from "./lib/errors.js";
import { requestContext } from "./lib/request-context.js";
import { openapi } from "./openapi.js";
import { prisma } from "@leetlogic/database";
import { redis } from "./lib/redis.js";

export function createApp(): Express {
  const app = express(); app.disable("x-powered-by"); app.use(helmet()); app.use(cors({ origin: false })); app.use(express.json({ limit: "1mb" })); app.use(requestContext); app.use(pinoHttp({ genReqId: (req: Request) => req.requestId ?? crypto.randomUUID(), redact: ["req.headers.authorization", "req.body.code", "req.body.refreshToken", "req.body.preAuthToken"] }));
  app.get("/health/live", (_req, res) => res.json({ status: "ok" }));
  app.get("/health/ready", async (_req, res) => { await Promise.all([prisma.$queryRaw`SELECT 1`, redis().ping()]); res.json({ status: "ready" }); });
  app.use("/docs", swaggerUi.serve, swaggerUi.setup(openapi)); app.get("/openapi.json", (_req, res) => res.json(openapi));
  app.use("/v1/auth", authRouter); app.use("/v1/me", meRouter); app.use("/v1/seller/verification", verificationRouter); app.use("/v1/admin/auth", adminAuthRouter); app.use("/v1/admin", adminRouter);
  app.use(notFound); app.use(errorHandler); return app;
}
