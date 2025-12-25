// Supabase Edge Function: 테스트 푸시 발송
// 어드민에서 특정 사용자에게 테스트 푸시를 발송

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

interface ServiceAccount {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
}

// OAuth 2.0 액세스 토큰 생성
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const privateKey = serviceAccount.private_key;
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwtPayload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: getNumericDate(0),
    exp: getNumericDate(3600),
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const jwt = await create({ alg: "RS256", typ: "JWT" }, jwtPayload, cryptoKey);

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const error = await tokenResponse.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

// FCM v1 API로 푸시 전송
async function sendFCMMessage(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  pushType: string
): Promise<any> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data: {
        type: "test",
        pushType,
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default", badge: 1 },
        },
      },
    },
  };

  const response = await fetch(fcmUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify(message),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`FCM API error: ${response.status} - ${errorText}`);
  }

  return await response.json();
}

serve(async (req) => {
  // CORS 헤더 설정
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (!FIREBASE_SERVICE_ACCOUNT) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let serviceAccount: ServiceAccount;
    try {
      serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid FIREBASE_SERVICE_ACCOUNT format" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Supabase 클라이언트 생성
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

    // 요청 본문 파싱
    const { userId, title, body, pushType } = await req.json();

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: "userId, title, and body are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 사용자의 FCM 토큰 가져오기
    const { data: tokens, error: tokensError } = await supabaseClient
      .from("fcm_tokens")
      .select("token")
      .eq("user_id", userId)
      .eq("notification_enabled", true);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "No FCM tokens found for this user",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OAuth 토큰 가져오기
    const accessToken = await getAccessToken(serviceAccount);

    // 각 토큰에 푸시 전송
    const sendResults = await Promise.allSettled(
      tokens.map((t) =>
        sendFCMMessage(
          accessToken,
          serviceAccount.project_id,
          t.token,
          title,
          body,
          pushType || "test"
        )
      )
    );

    const successCount = sendResults.filter((r) => r.status === "fulfilled").length;
    const failedCount = sendResults.filter((r) => r.status === "rejected").length;

    // 테스트 발송 로그 저장
    await supabaseClient.from("push_logs").insert({
      user_id: userId,
      push_type: "test",
      title,
      body,
    });

    // 무효한 토큰 정리
    const failedTokens: string[] = [];
    sendResults.forEach((result, index) => {
      if (result.status === "rejected") {
        const error = (result as PromiseRejectedResult).reason?.message || "";
        if (error.includes("UNREGISTERED") || error.includes("INVALID_ARGUMENT")) {
          failedTokens.push(tokens[index].token);
        }
      }
    });

    if (failedTokens.length > 0) {
      await supabaseClient
        .from("fcm_tokens")
        .delete()
        .in("token", failedTokens);
      console.log(`Removed ${failedTokens.length} invalid tokens`);
    }

    return new Response(
      JSON.stringify({
        success: successCount > 0,
        sentCount: successCount,
        failedCount,
        message:
          successCount > 0
            ? `Successfully sent to ${successCount} device(s)`
            : "Failed to send to any device",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
