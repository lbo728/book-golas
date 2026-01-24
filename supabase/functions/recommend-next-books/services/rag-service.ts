import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SupabaseVectorStore } from "https://esm.sh/@langchain/community@0.0.43/vectorstores/supabase";
import { OpenAIEmbeddings } from "https://esm.sh/@langchain/openai@0.0.28";
import { Document } from "https://esm.sh/@langchain/core@0.1.45/documents";
import { config } from "../config.ts";
import { extractKeywords } from "../utils/keyword-extractor.ts";

interface HighlightWithBook {
  content: string;
  bookTitle: string;
}

interface UserInterests {
  topHighlights: HighlightWithBook[];
  keywords: string[];
}

export async function extractUserInterests(
  supabase: SupabaseClient,
  userId: string
): Promise<UserInterests> {
  const embeddings = new OpenAIEmbeddings({
    openAIApiKey: config.openai.apiKey,
  });

  const vectorStore = new SupabaseVectorStore(embeddings, {
    client: supabase,
    tableName: "reading_content_embeddings",
    queryName: "match_user_interests",
  });

  const interestQuery = "독서에서 중요하게 생각하는 주제와 개념";

  const results = await vectorStore.similaritySearch(
    interestQuery,
    config.rag.topHighlightsCount,
    { user_id: userId }
  );

  if (results.length === 0) {
    return { topHighlights: [], keywords: [] };
  }

  const bookIds = [
    ...new Set(results.map((doc: Document) => doc.metadata.book_id as string)),
  ];

  const { data: books } = await supabase
    .from("books")
    .select("id, title")
    .in("id", bookIds);

  const bookTitleMap = new Map<string, string>(
    books?.map((b: { id: string; title: string }) => [b.id, b.title]) || []
  );

  const topHighlights: HighlightWithBook[] = results.map((doc: Document) => ({
    content: doc.pageContent,
    bookTitle: bookTitleMap.get(doc.metadata.book_id as string) || "Unknown",
  }));

  const keywords = extractKeywords(
    topHighlights.map((h) => h.content).join(" "),
    config.rag.topKeywordsCount
  );

  return { topHighlights, keywords };
}
