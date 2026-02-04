import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const REVENUECAT_WEBHOOK_AUTH_KEY = Deno.env.get("REVENUECAT_WEBHOOK_AUTH_KEY");

interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  product_id: string;
  transaction_id: string;
  expiration_at_ms?: number;
  original_transaction_id?: string;
  price_in_purchased_currency?: number;
  currency?: string;
}

interface RevenueCatWebhookPayload {
  event: RevenueCatEvent;
}

type SubscriptionStatus = "free" | "pro_monthly" | "pro_yearly" | "pro_lifetime";

function mapProductIdToStatus(productId: string): SubscriptionStatus {
  if (productId.includes("lifetime")) {
    return "pro_lifetime";
  } else if (productId.includes("yearly") || productId.includes("annual")) {
    return "pro_yearly";
  } else if (productId.includes("monthly")) {
    return "pro_monthly";
  }
  return "pro_monthly";
}

function mapEventTypeToDbEventType(eventType: string): string {
  const mapping: Record<string, string> = {
    INITIAL_PURCHASE: "initial_purchase",
    RENEWAL: "renewal",
    CANCELLATION: "cancellation",
    EXPIRATION: "expiration",
    REFUND: "refund",
    BILLING_ISSUE: "billing_issue",
  };
  return mapping[eventType] || eventType.toLowerCase();
}

function shouldUpdateToFreeStatus(eventType: string): boolean {
  return ["CANCELLATION", "EXPIRATION", "REFUND"].includes(eventType);
}

function shouldUpdateToPaidStatus(eventType: string): boolean {
  return ["INITIAL_PURCHASE", "RENEWAL"].includes(eventType);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers":
          "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("authorization");
    if (REVENUECAT_WEBHOOK_AUTH_KEY && authHeader !== `Bearer ${REVENUECAT_WEBHOOK_AUTH_KEY}`) {
      console.error("Unauthorized webhook request");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const payload: RevenueCatWebhookPayload = await req.json();
    const event = payload.event;

    console.log(`Processing RevenueCat event: ${event.type} for user: ${event.app_user_id}`);

    if (!event.type || !event.app_user_id) {
      return new Response(
        JSON.stringify({ error: "Missing required event fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    const { data: user, error: userError } = await supabaseClient
      .from("users")
      .select("id")
      .eq("revenuecat_user_id", event.app_user_id)
      .single();

    if (userError || !user) {
      console.error(`User not found for RevenueCat ID: ${event.app_user_id}`, userError);
      return new Response(
        JSON.stringify({ error: "User not found", revenuecat_user_id: event.app_user_id }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`Found user: ${user.id}`);

    if (shouldUpdateToPaidStatus(event.type)) {
      const subscriptionStatus = mapProductIdToStatus(event.product_id);
      const expiresAt = event.expiration_at_ms
        ? new Date(event.expiration_at_ms).toISOString()
        : null;

      const { error: updateError } = await supabaseClient
        .from("users")
        .update({
          subscription_status: subscriptionStatus,
          subscription_expires_at: subscriptionStatus === "pro_lifetime" ? null : expiresAt,
        })
        .eq("id", user.id);

      if (updateError) {
        console.error("Failed to update user subscription:", updateError);
        throw updateError;
      }

      console.log(`Updated user ${user.id} to ${subscriptionStatus}, expires: ${expiresAt}`);
    } else if (shouldUpdateToFreeStatus(event.type)) {
      const { error: updateError } = await supabaseClient
        .from("users")
        .update({
          subscription_status: "free",
          subscription_expires_at: null,
        })
        .eq("id", user.id);

      if (updateError) {
        console.error("Failed to update user subscription to free:", updateError);
        throw updateError;
      }

      console.log(`Updated user ${user.id} to free status`);
    }

    const { error: eventError } = await supabaseClient
      .from("subscription_events")
      .insert({
        user_id: user.id,
        event_type: mapEventTypeToDbEventType(event.type),
        product_id: event.product_id,
        transaction_id: event.transaction_id,
        payload: payload,
      });

    if (eventError) {
      console.error("Failed to log subscription event:", eventError);
    } else {
      console.log(`Logged subscription event: ${event.type}`);
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error: unknown) {
    console.error("Error processing webhook:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
