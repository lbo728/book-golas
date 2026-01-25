-- Migration: AI Book Recommendation System
-- Description: LangChain RAG 기반 도서 추천 시스템을 위한 벡터 검색 함수 생성
-- Issue: BYU-280

-- 1. 사용자 관심사 벡터 검색 함수
-- LangChain SupabaseVectorStore에서 사용하는 공식 패턴 준수
CREATE OR REPLACE FUNCTION match_user_interests(
  query_embedding extensions.vector(1536),
  match_count int DEFAULT 10,
  filter jsonb DEFAULT '{}'
)
RETURNS TABLE (
  id uuid,
  content text,
  metadata jsonb,
  similarity float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
#variable_conflict use_column
DECLARE
  filter_user_id uuid;
BEGIN
  -- filter에서 user_id 추출
  filter_user_id := (filter->>'user_id')::uuid;
  
  RETURN QUERY
  SELECT
    reading_content_embeddings.id,
    reading_content_embeddings.content_text AS content,
    jsonb_build_object(
      'book_id', reading_content_embeddings.book_id,
      'content_type', reading_content_embeddings.content_type,
      'page_number', reading_content_embeddings.page_number,
      'source_id', reading_content_embeddings.source_id,
      'user_id', reading_content_embeddings.user_id
    ) AS metadata,
    1 - (reading_content_embeddings.embedding <=> query_embedding) AS similarity
  FROM reading_content_embeddings
  WHERE 
    (filter_user_id IS NULL OR reading_content_embeddings.user_id = filter_user_id)
    AND reading_content_embeddings.embedding IS NOT NULL
  ORDER BY reading_content_embeddings.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

COMMENT ON FUNCTION match_user_interests IS 'LangChain RAG용 벡터 유사도 검색 함수 - 사용자의 하이라이트/메모에서 관심사 추출';

-- 2. 추천 결과 저장 테이블 (분석 및 캐싱용)
CREATE TABLE IF NOT EXISTS book_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 추천 결과
  recommendations JSONB NOT NULL,
  
  -- 분석에 사용된 프로필 요약
  profile_summary JSONB,
  
  -- 메타데이터
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 만료 시간 (캐싱용 - 기본 7일)
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days'
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_book_recommendations_user 
  ON book_recommendations(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_book_recommendations_expires 
  ON book_recommendations(expires_at);

-- RLS 정책
ALTER TABLE book_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recommendations"
  ON book_recommendations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recommendations"
  ON book_recommendations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own recommendations"
  ON book_recommendations FOR DELETE
  USING (auth.uid() = user_id);

-- 3. 만료된 추천 자동 삭제 함수
CREATE OR REPLACE FUNCTION cleanup_expired_recommendations()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM book_recommendations
  WHERE expires_at < NOW();
END;
$$;

COMMENT ON FUNCTION cleanup_expired_recommendations IS '만료된 추천 캐시 정리 (pg_cron으로 주기적 실행)';

-- 4. 코멘트 추가
COMMENT ON TABLE book_recommendations IS 'AI 도서 추천 결과 저장 (캐싱 및 분석용)';
