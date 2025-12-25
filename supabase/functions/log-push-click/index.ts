// Supabase Edge Function: 푸시 클릭 이벤트 로깅
// 클라이언트에서 푸시 알림 탭 시 호출하여 클릭 여부를 기록

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
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

  try {
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

    // 요청 본문 파싱
    const { logId, userId, pushType } = await req.json();

    // logId가 있으면 해당 로그 업데이트
    if (logId) {
      const { error } = await supabaseClient
        .from("push_logs")
        .update({
          is_clicked: true,
          clicked_at: new Date().toISOString(),
        })
        .eq("id", logId);

      if (error) {
        console.error("Error updating push log by id:", error);
        return new Response(
          JSON.stringify({ error: "Failed to update push log" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ success: true, method: "logId" }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // userId와 pushType으로 최근 로그 찾아서 업데이트
    if (userId && pushType) {
      // 최근 24시간 이내의 해당 타입 로그 중 클릭되지 않은 가장 최근 것
      const oneDayAgo = new Date();
      oneDayAgo.setDate(oneDayAgo.getDate() - 1);

      const { data: recentLog, error: findError } = await supabaseClient
        .from("push_logs")
        .select("id")
        .eq("user_id", userId)
        .eq("push_type", pushType)
        .eq("is_clicked", false)
        .gte("sent_at", oneDayAgo.toISOString())
        .order("sent_at", { ascending: false })
        .limit(1)
        .single();

      if (findError || !recentLog) {
        console.log("No matching push log found:", findError?.message);
        return new Response(
          JSON.stringify({ success: false, message: "No matching log found" }),
          {
            status: 200,
            headers: {
              "Content-Type": "application/json",
              "Access-Control-Allow-Origin": "*",
            },
          }
        );
      }

      const { error: updateError } = await supabaseClient
        .from("push_logs")
        .update({
          is_clicked: true,
          clicked_at: new Date().toISOString(),
        })
        .eq("id", recentLog.id);

      if (updateError) {
        console.error("Error updating push log:", updateError);
        return new Response(
          JSON.stringify({ error: "Failed to update push log" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ success: true, method: "userId+pushType", logId: recentLog.id }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "Either logId or (userId + pushType) is required" }),
      {
        status: 400,
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
