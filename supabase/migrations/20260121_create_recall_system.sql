-- Migration: Create AI Recall Search System
-- Description: 독서 기록 AI 검색 시스템을 위한 테이블 및 함수 생성

-- 1. pgvector extension 활성화
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- 2. 벡터 임베딩 저장 테이블
CREATE TABLE IF NOT EXISTS reading_content_embeddings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  
  -- 원본 콘텐츠
  content_type TEXT NOT NULL CHECK (content_type IN ('highlight', 'note', 'photo_ocr')),
  content_text TEXT NOT NULL,
  page_number INT,
  
  -- 벡터 임베딩 (OpenAI text-embedding-3-small = 1536 dimensions)
  embedding extensions.vector(1536),
  
  -- 메타데이터
  source_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 중복 방지
  CONSTRAINT unique_source UNIQUE (content_type, source_id)
);

-- 3. 벡터 유사도 검색 인덱스 (HNSW - cosine distance)
CREATE INDEX IF NOT EXISTS idx_embeddings_hnsw 
ON reading_content_embeddings 
USING hnsw (embedding extensions.vector_cosine_ops);

-- 4. 사용자별 빠른 조회 인덱스
CREATE INDEX IF NOT EXISTS idx_embeddings_user_book 
ON reading_content_embeddings(user_id, book_id);

-- 5. RLS 정책
ALTER TABLE reading_content_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own embeddings"
  ON reading_content_embeddings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own embeddings"
  ON reading_content_embeddings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own embeddings"
  ON reading_content_embeddings FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own embeddings"
  ON reading_content_embeddings FOR DELETE
  USING (auth.uid() = user_id);

-- 6. 검색 히스토리 테이블 (분석용)
CREATE TABLE IF NOT EXISTS recall_search_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  
  query TEXT NOT NULL,
  answer TEXT,
  sources JSONB,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_recall_history_user 
ON recall_search_history(user_id, created_at DESC);

ALTER TABLE recall_search_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own search history"
  ON recall_search_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own search history"
  ON recall_search_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 7. 벡터 유사도 검색 함수
CREATE OR REPLACE FUNCTION match_reading_content(
  query_embedding extensions.vector(1536),
  match_count INT DEFAULT 5,
  filter_user_id UUID DEFAULT NULL,
  filter_book_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  content_text TEXT,
  content_type TEXT,
  page_number INT,
  source_id UUID,
  created_at TIMESTAMPTZ,
  similarity FLOAT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    rce.id,
    rce.content_text,
    rce.content_type,
    rce.page_number,
    rce.source_id,
    rce.created_at,
    1 - (rce.embedding <=> query_embedding) AS similarity
  FROM reading_content_embeddings rce
  WHERE 
    (filter_user_id IS NULL OR rce.user_id = filter_user_id) AND
    (filter_book_id IS NULL OR rce.book_id = filter_book_id) AND
    rce.embedding IS NOT NULL
  ORDER BY rce.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;

-- 8. 코멘트 추가
COMMENT ON TABLE reading_content_embeddings IS 'AI 검색을 위한 독서 콘텐츠 벡터 임베딩 저장';
COMMENT ON TABLE recall_search_history IS 'AI 검색 히스토리 (분석용)';
COMMENT ON FUNCTION match_reading_content IS '벡터 유사도 기반 독서 콘텐츠 검색';
