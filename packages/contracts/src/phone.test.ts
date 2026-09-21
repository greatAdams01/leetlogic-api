import { describe, expect, it } from "vitest";
import { normalizeNigerianPhone } from "./phone.js";

describe("normalizeNigerianPhone", () => {
  it.each([["0803 123 4567", "+2348031234567"], ["+234-803-123-4567", "+2348031234567"]])("normalizes %s", (input, expected) => {
    expect(normalizeNigerianPhone(input)).toBe(expected);
  });
  it.each(["+12025550123", "0123", "not-a-phone"])("rejects %s", (input) => {
    expect(() => normalizeNigerianPhone(input)).toThrow("INVALID_NIGERIAN_PHONE");
  });
});

