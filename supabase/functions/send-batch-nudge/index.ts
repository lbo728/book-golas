// Supabase Edge Function: 배치 스마트 넛지 푸시 알림 (HTTP v1 API)
// 사용자별 선호 시간대에 맞춰 스마트 넛지 분석 후 푸시 전송
// GitHub Actions 스케줄러에서 매 시간 호출 → 현재 시간과 preferred_hour가 일치하는 사용자만 처리

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

interface NudgeResult {
  userId: string;
  nudgeType: string | null;
  success: boolean;
  error?: string;
}

interface NudgeAnalysis {
  type: "inactive" | "progress" | "streak" | "deadline" | "achievement";
  title: string;
  body: string;
  data?: Record<string, string>;
}

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

// OAuth 2.0 액세스 토큰 캐시
let cachedAccessToken: string | null = null;
let tokenExpiry: number = 0;

// 서비스 계정으로 OAuth 2.0 액세스 토큰 생성
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  if (cachedAccessToken && tokenExpiry > now + 60) {
    return cachedAccessToken;
  }

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
  cachedAccessToken = tokenData.access_token;
  tokenExpiry = now + tokenData.expires_in;

  return cachedAccessToken!;
}

// FCM v1 API로 푸시 전송
async function sendFCMMessage(
  accessToken: string,
  projectId: string,
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<any> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  const message = {
    message: {
      token: fcmToken,
      notification: { title, body },
      data: data || {},
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
  try {
    // CORS 헤더 설정
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

    if (!FIREBASE_SERVICE_ACCOUNT) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    let serviceAccount: ServiceAccount;
    try {
      serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid FIREBASE_SERVICE_ACCOUNT format" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // Supabase 클라이언트 생성 (서비스 역할)
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

    // 현재 KST 시간 계산
    const now = new Date();
    const kstHour = (now.getUTCHours() + 9) % 24;
    console.log(`Current KST hour: ${kstHour}`);

    // 알림 활성화 + 현재 시간대에 알림 받기를 원하는 사용자만 조회
    const { data: usersWithTokens, error: usersError } = await supabaseClient
      .from("fcm_tokens")
      .select("user_id, token, preferred_hour")
      .eq("notification_enabled", true)
      .eq("preferred_hour", kstHour)
      .order("user_id");

    if (usersError) {
      console.error("Error fetching users with tokens:", usersError);
      return new Response(
        JSON.stringify({
          error: "Failed to fetch users",
          details: usersError.message,
        }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    if (!usersWithTokens || usersWithTokens.length === 0) {
      return new Response(
        JSON.stringify({
          message: `No users with FCM tokens found for hour ${kstHour} KST`,
          currentHourKST: kstHour,
          sent: 0,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // 사용자별로 토큰 그룹화
    const userTokensMap = new Map<string, string[]>();
    usersWithTokens.forEach((row) => {
      const tokens = userTokensMap.get(row.user_id) || [];
      tokens.push(row.token);
      userTokensMap.set(row.user_id, tokens);
    });

    // OAuth 2.0 액세스 토큰 가져오기 (한 번만)
    const accessToken = await getAccessToken(serviceAccount);

    const results: NudgeResult[] = [];
    let totalSent = 0;
    let totalSkipped = 0;
    let totalFailed = 0;

    // 각 사용자에 대해 넛지 분석 및 전송
    for (const [userId, tokens] of userTokensMap) {
      try {
        // 사용자의 독서 상태 분석
        const nudge = await analyzeUserReadingState(supabaseClient, userId);

        if (!nudge) {
          results.push({ userId, nudgeType: null, success: true });
          totalSkipped++;
          continue;
        }

        // FCM 푸시 전송
        const sendResults = await Promise.allSettled(
          tokens.map((fcmToken) =>
            sendFCMMessage(
              accessToken,
              serviceAccount.project_id,
              fcmToken,
              nudge.title,
              nudge.body,
              {
                type: "smart_nudge",
                nudgeType: nudge.type,
                ...nudge.data,
              }
            )
          )
        );

        const successCount = sendResults.filter(
          (r) => r.status === "fulfilled"
        ).length;

        if (successCount > 0) {
          results.push({ userId, nudgeType: nudge.type, success: true });
          totalSent++;

          // push_logs에 발송 기록 저장
          await supabaseClient.from("push_logs").insert({
            user_id: userId,
            push_type: nudge.type,
            book_id: nudge.data?.bookId || null,
            title: nudge.title,
            body: nudge.body,
          });
        } else {
          results.push({
            userId,
            nudgeType: nudge.type,
            success: false,
            error: "All sends failed",
          });
          totalFailed++;
        }

        // 무효한 토큰 정리
        const failedTokens: string[] = [];
        sendResults.forEach((result, index) => {
          if (result.status === "rejected") {
            const error =
              (result as PromiseRejectedResult).reason?.message || "";
            if (
              error.includes("UNREGISTERED") ||
              error.includes("INVALID_ARGUMENT")
            ) {
              failedTokens.push(tokens[index]);
            }
          }
        });

        if (failedTokens.length > 0) {
          await supabaseClient
            .from("fcm_tokens")
            .delete()
            .in("token", failedTokens);
          console.log(
            `Removed ${failedTokens.length} invalid tokens for user ${userId}`
          );
        }
      } catch (error) {
        console.error(`Error processing user ${userId}:`, error);
        results.push({
          userId,
          nudgeType: null,
          success: false,
          error: error.message,
        });
        totalFailed++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        currentHourKST: kstHour,
        summary: {
          totalUsers: userTokensMap.size,
          sent: totalSent,
          skipped: totalSkipped,
          failed: totalFailed,
        },
        details: results,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }
});

// 푸시 템플릿 캐시
let templatesCache: Map<string, { title: string; body_template: string }> | null = null;

// 푸시 템플릿 로드
async function loadPushTemplates(supabaseClient: any): Promise<Map<string, { title: string; body_template: string }>> {
  if (templatesCache) return templatesCache;

  const { data: templates } = await supabaseClient
    .from("push_templates")
    .select("type, title, body_template")
    .eq("is_active", true);

  templatesCache = new Map();
  if (templates) {
    templates.forEach((t: any) => {
      templatesCache!.set(t.type, { title: t.title, body_template: t.body_template });
    });
  }
  return templatesCache;
}

// 템플릿 변수 치환
function replaceTemplateVariables(template: string, variables: Record<string, string>): string {
  let result = template;
  for (const [key, value] of Object.entries(variables)) {
    result = result.replace(new RegExp(`\\{${key}\\}`, 'g'), value);
  }
  return result;
}

// 사용자의 독서 상태를 분석하여 맞춤형 넛지 생성
async function analyzeUserReadingState(
  supabaseClient: any,
  userId: string
): Promise<NudgeAnalysis | null> {
  const now = new Date();

  // 1. 사용자의 활성 책 목록 가져오기
  const { data: books, error: booksError } = await supabaseClient
    .from("books")
    .select("*")
    .eq("user_id", userId)
    .order("updated_at", { ascending: false });

  if (booksError || !books || books.length === 0) {
    return null;
  }

  // 2. 마지막 독서 시간 확인
  const lastBook = books[0];
  const lastReadingDate = lastBook.updated_at
    ? new Date(lastBook.updated_at)
    : null;
  const daysSinceLastReading = lastReadingDate
    ? Math.floor(
        (now.getTime() - lastReadingDate.getTime()) / (1000 * 60 * 60 * 24)
      )
    : null;

  // 3. 가장 최근 책 정보
  const currentBook = books[0];
  const progress =
    currentBook.total_pages > 0
      ? currentBook.current_page / currentBook.total_pages
      : 0;
  const targetDate = currentBook.target_date
    ? new Date(currentBook.target_date)
    : null;
  const daysUntilDeadline = targetDate
    ? Math.ceil((targetDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
    : null;

  // 4. 독서 연속일 계산
  const sevenDaysAgo = new Date(now);
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const readingDates = new Set<string>();
  books.forEach((book: any) => {
    if (book.updated_at) {
      const date = new Date(book.updated_at);
      if (date >= sevenDaysAgo) {
        readingDates.add(
          `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`
        );
      }
    }
  });
  const streak = readingDates.size;

  // 5. 넛지 타입 결정 (우선순위: 비활성 > 마감일 임박 > 진행률 > 연속일)
  let nudgeType: string = "";
  let variables: Record<string, string> = {};

  if (daysSinceLastReading !== null && daysSinceLastReading >= 3) {
    nudgeType = "inactive";
    variables = { days: String(daysSinceLastReading), bookTitle: currentBook.title };
  } else if (
    daysUntilDeadline !== null &&
    daysUntilDeadline > 0 &&
    daysUntilDeadline <= 3
  ) {
    nudgeType = "deadline";
    variables = { days: String(daysUntilDeadline), bookTitle: currentBook.title };
  } else if (progress >= 0.8 && progress < 1.0) {
    nudgeType = "progress";
    variables = { percent: String(Math.round(progress * 100)), bookTitle: currentBook.title };
  } else if (streak > 0 && streak < 7) {
    nudgeType = "streak";
    variables = { days: String(streak) };
  } else {
    return null;
  }

  // 6. 템플릿에서 메시지 생성
  const templates = await loadPushTemplates(supabaseClient);
  const template = templates.get(nudgeType);

  let title = "";
  let body = "";

  if (template) {
    title = template.title;
    body = replaceTemplateVariables(template.body_template, variables);
  } else {
    // 템플릿이 없을 경우 기본 메시지 (fallback)
    title = "독서 알림 📚";
    body = "오늘도 독서 목표를 향해 나아가세요!";
  }

  const data: Record<string, string> = {
    bookId: currentBook.id,
    bookTitle: currentBook.title,
    ...variables,
  };

  return {
    type: nudgeType as any,
    title,
    body,
    data,
  };
}
