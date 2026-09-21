import { describe, expect, it } from "vitest";
import { requestFingerprint } from "./idempotency.js";

describe("idempotency request fingerprint", () => {
  it("is stable for the same payload and changes with the payload", () => {
    expect(requestFingerprint({ quantity: "1.500" })).toBe(requestFingerprint({ quantity: "1.500" }));
    expect(requestFingerprint({ quantity: "1.500" })).not.toBe(requestFingerprint({ quantity: "2.000" }));
  });
});
