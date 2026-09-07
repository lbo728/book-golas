import { describe, expect, it } from "vitest";
import { getSafeNextPath } from "./paths";

describe("consumer next paths", () => {
  it("keeps a locale-preserving consumer path", () => {
    expect(getSafeNextPath("ko", "/ko/books/123")).toBe("/ko/books/123");
  });

  it.each([
    "/ko/../../admin",
    "/ko/%2e%2e/%2e%2e/admin",
    "/ko/%252e%252e/admin",
    "/ko/home%3F/../../admin",
    "/ko/home?/../../admin",
    "/ko//admin",
    "/ko\\admin",
    "/ko/home%5c..%5cadmin",
    "/ko/%255c..%255cadmin",
    "/ko/%25255c..%25255cadmin",
  ])(
    "rejects unsafe path segments: %s",
    (candidate) => {
      expect(getSafeNextPath("ko", candidate)).toBe("/ko/home");
    },
  );
});
