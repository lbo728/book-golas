import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

interface SearchRequest {
  bookId: string;
  query: string;
}

interface SourceDocument {
  type: string;
  content: string;
  pageNumber: number | null;
  sourceId: string | null;
  createdAt: string;
}

async function generateEmbedding(text: string): Promise<number[]> {
  const response = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "text-embedding-3-small",
      input: text,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return data.data[0].embedding;
}

async function generateAnswer(
  query: string,
  context: string
): Promise<string> {
  const systemPrompt = `당신은 독자의 독서 기록을 검색하는 AI입니다.
사용자가 직접 하이라이트하거나 메모한 내용만을 기반으로 답변하세요.
책의 일반적인 내용이 아닌, '사용자가 중요하게 본 부분'을 강조하세요.

답변 형식:
- 자연스러운 대화체
- 페이지 번호 명시 (알 수 있는 경우)
- "당신이 하이라이트한...", "당신이 메모한..." 등 개인화된 표현 사용
- 관련 기록이 없으면 솔직하게 "관련 기록을 찾지 못했습니다"라고 답변`;

  const userPrompt = `질문: ${query}

관련 기록:
${context}`;

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.3,
      max_tokens: 1000,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${response.status} - ${error}`);
  }

  const data = await response.json();
  return data.choices[0].message.content;
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
    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const authHeader = req.headers.get("Authorization");
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader ?? "" } } }
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { bookId, query }: SearchRequest = await req.json();

    if (!bookId || !query) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: bookId, query" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const queryEmbedding = await generateEmbedding(query);
    const embeddingString = `[${queryEmbedding.join(",")}]`;

    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    const { data: searchResults, error: searchError } = await serviceClient.rpc(
      "match_reading_content",
      {
        query_embedding: embeddingString,
        match_count: 5,
        filter_user_id: user.id,
        filter_book_id: bookId,
      }
    );

    if (searchError) {
      throw searchError;
    }

    if (!searchResults || searchResults.length === 0) {
      return new Response(
        JSON.stringify({
          answer:
            "관련 기록을 찾지 못했습니다. 더 많은 하이라이트나 메모를 추가해보세요!",
          sources: [],
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const context = searchResults
      .map((result: any, index: number) => {
        const typeLabel =
          result.content_type === "highlight"
            ? "하이라이트"
            : result.content_type === "note"
            ? "메모"
            : "사진 속 텍스트";
        const pageInfo = result.page_number
          ? ` (${result.page_number}페이지)`
          : "";
        return `[${index + 1}] ${typeLabel}${pageInfo}:\n${result.content_text}`;
      })
      .join("\n\n");

    const answer = await generateAnswer(query, context);

    const sources: SourceDocument[] = searchResults.map((result: any) => ({
      type: result.content_type,
      content: result.content_text,
      pageNumber: result.page_number,
      sourceId: result.source_id,
      createdAt: result.created_at,
    }));

    await serviceClient.from("recall_search_history").insert({
      user_id: user.id,
      book_id: bookId,
      query: query,
      answer: answer,
      sources: sources,
    });

    return new Response(
      JSON.stringify({
        answer,
        sources,
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
