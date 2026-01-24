import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { config, validateConfig } from "./config.ts";
import { ProfileCollector } from "./services/profile-collector.ts";
import { RecommendationService } from "./services/recommendation-service.ts";
import type { RecommendationResponse } from "./types.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    validateConfig();

    const { userId } = await req.json();
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "userId is required" }),
        {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    const supabase = createClient(
      config.supabase.url,
      config.supabase.serviceRoleKey
    );

    console.log(`[recommend-next-books] Collecting profile for user: ${userId}`);
    const profileCollector = new ProfileCollector(supabase);
    const profile = await profileCollector.collect(userId);

    if (profile.books.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "No completed books found",
          recommendations: [],
          profile: { stats: profile.stats, booksAnalyzed: 0 },
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    console.log(`[recommend-next-books] Generating recommendations...`);
    const recommendationService = new RecommendationService();
    const recommendations = await recommendationService.generate(profile);

    const response: RecommendationResponse = {
      success: true,
      recommendations,
      profile: {
        stats: profile.stats,
        booksAnalyzed: profile.books.length,
      },
    };

    await saveRecommendations(supabase, userId, response);

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  } catch (error: unknown) {
    const errorMessage =
      error instanceof Error ? error.message : "Unknown error";
    console.error("[recommend-next-books] Error:", errorMessage);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});

async function saveRecommendations(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  response: RecommendationResponse
): Promise<void> {
  try {
    await supabase.from("book_recommendations").insert({
      user_id: userId,
      recommendations: response.recommendations,
      profile_summary: response.profile,
    });
  } catch (error) {
    console.error("[recommend-next-books] Failed to save recommendations:", error);
  }
}
