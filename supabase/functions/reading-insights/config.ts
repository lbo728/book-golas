export const config = {
  openai: {
    apiKey: Deno.env.get("OPENAI_API_KEY") || "",
    model: "gpt-4o-mini",
    temperature: 0.7,
  },
  supabase: {
    url: Deno.env.get("SUPABASE_URL") || "",
    serviceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "",
  },
  insights: {
    maxBooksToAnalyze: 10,
    minHighlightsForInsight: 3,
  },
};

export function validateConfig(): void {
  if (!config.openai.apiKey) {
    throw new Error("OPENAI_API_KEY not configured");
  }
  if (!config.supabase.url || !config.supabase.serviceRoleKey) {
    throw new Error("Supabase credentials not configured");
  }
}
