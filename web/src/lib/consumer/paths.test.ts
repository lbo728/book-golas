import { describe, expect, it } from "vitest";
import { getSafeNextPath } from "./paths";

describe("consumer next paths", () => {
  it("keeps a locale-preserving consumer path", () => {
    expect(getSafeNextPath("ko", "/ko/books/123")).toBe("/ko/books/123");
  });

  it.each(["/ko/../../admin", "/ko/%2e%2e/%2e%2e/admin", "/ko//admin", "/ko\\admin"])(
    "rejects unsafe path segments: %s",
    (candidate) => {
      expect(getSafeNextPath("ko", candidate)).toBe("/ko/home");
    },
  );
});
