-- Migration: Add book_id to match_reading_content function return type
-- Description: Update RPC function to return book_id for global search support

-- Drop existing function first (required to change return type)
DROP FUNCTION IF EXISTS match_reading_content(extensions.vector(1536), INT, UUID, UUID);

-- Recreate with book_id in return type
CREATE OR REPLACE FUNCTION match_reading_content(
  query_embedding extensions.vector(1536),
  match_count INT DEFAULT 5,
  filter_user_id UUID DEFAULT NULL,
  filter_book_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  book_id UUID,
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
    rce.book_id,
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

COMMENT ON FUNCTION match_reading_content IS '벡터 유사도 기반 독서 콘텐츠 검색 (book_id 포함)';
