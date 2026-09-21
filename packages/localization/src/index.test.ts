import { describe, expect, it } from "vitest";
import { translate, translations } from "./index.js";
describe("translations", () => {
  it("contains all five launch locales", () => expect(Object.keys(translations)).toEqual(["en", "pcm", "ig", "ha", "yo"]));
  it("returns translated content", () => expect(translate("pcm", "seller.verification.pending")).toContain("check"));
});

