import { beforeEach, describe, expect, it, vi } from "vitest";
import { createServerSupabaseClient } from "@/lib/supabase-server";
import { fetchOwnedBook } from "./queries";

vi.mock("@/lib/supabase-server", () => ({
  createServerSupabaseClient: vi.fn(),
}));

function makeSupabase(user: { id: string } | null) {
  const from = vi.fn();
  const supabase = {
    auth: {
      getUser: vi.fn().mockResolvedValue({
        data: { user },
        error: null,
      }),
    },
    from,
  };

  return { supabase, from };
}

describe("fetchOwnedBook malformed identifiers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("preserves authenticated header state without querying books", async () => {
    const { supabase, from } = makeSupabase({ id: "user-1" });
    vi.mocked(createServerSupabaseClient).mockResolvedValue(supabase as never);

    await expect(fetchOwnedBook("not-a-book-id")).resolves.toEqual({
      book: null,
      code: "not_found",
      authenticated: true,
    });
    expect(supabase.auth.getUser).toHaveBeenCalledTimes(1);
    expect(from).not.toHaveBeenCalled();
  });

  it("keeps anonymous malformed requests unauthenticated without querying books", async () => {
    const { supabase, from } = makeSupabase(null);
    vi.mocked(createServerSupabaseClient).mockResolvedValue(supabase as never);

    await expect(fetchOwnedBook("not-a-book-id")).resolves.toEqual({
      book: null,
      code: "not_found",
      authenticated: false,
    });
    expect(from).not.toHaveBeenCalled();
  });

  it("reports an unavailable session boundary without querying books", async () => {
    vi.mocked(createServerSupabaseClient).mockRejectedValue(new Error("network"));

    await expect(fetchOwnedBook("not-a-book-id")).resolves.toEqual({
      book: null,
      code: "unavailable",
      authenticated: false,
    });
  });
});
