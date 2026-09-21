import { describe, expect, it } from "vitest";
import { errorHandler } from "./errors.js";
import { z } from "zod";
import type { Request, Response } from "express";
describe("error envelope", () => {
  it("returns field errors and a request id", () => {
    let status = 0; let body: any;
    const response = { status(value: number) { status = value; return this; }, json(value: unknown) { body = value; return this; } } as unknown as Response;
    let error: unknown; try { z.object({ value: z.string().min(2) }).parse({ value: "" }); } catch (caught) { error = caught; }
    errorHandler(error, { requestId: "11111111-1111-4111-8111-111111111111" } as Request, response, () => undefined);
    expect(status).toBe(422); expect(body.error.code).toBe("VALIDATION_ERROR"); expect(body.error.requestId).toBeTruthy();
  });
});
