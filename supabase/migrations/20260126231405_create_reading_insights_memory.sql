-- Migration: Create Reading Insights Memory and Rate Limit Tables
-- Description: AI 독서 인사이트 생성을 위한 메모리 저장소 및 레이트 제한 테이블
-- Issue: BYU-XXX

-- 1. 독서 인사이트 메모리 테이블
-- AI가 생성한 인사이트를 저장하고 12개월 후 자동 삭제
CREATE TABLE IF NOT EXISTS reading_insights_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 인사이트 콘텐츠
  insight_content TEXT NOT NULL,
  
  -- 메타데이터 (생성 컨텍스트, 관련 책 등)
  insight_metadata JSONB,
  
  -- 타임스탬프
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- 만료 시간 (12개월 후 자동 삭제)
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '12 months'
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_reading_insights_memory_user 
  ON reading_insights_memory(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_reading_insights_memory_expires 
  ON reading_insights_memory(expires_at);

-- RLS 정책
ALTER TABLE reading_insights_memory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own insights memory"
  ON reading_insights_memory FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own insights memory"
  ON reading_insights_memory FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own insights memory"
  ON reading_insights_memory FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own insights memory"
  ON reading_insights_memory FOR DELETE
  USING (auth.uid() = user_id);

-- 2. 독서 인사이트 레이트 제한 테이블
-- 사용자별 마지막 인사이트 생성 시간 추적
CREATE TABLE IF NOT EXISTS reading_insights_rate_limit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 마지막 인사이트 생성 시간
  last_generated_at TIMESTAMPTZ
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_reading_insights_rate_limit_user 
  ON reading_insights_rate_limit(user_id);

-- RLS 정책
ALTER TABLE reading_insights_rate_limit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own rate limit"
  ON reading_insights_rate_limit FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rate limit"
  ON reading_insights_rate_limit FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own rate limit"
  ON reading_insights_rate_limit FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own rate limit"
  ON reading_insights_rate_limit FOR DELETE
  USING (auth.uid() = user_id);

-- 3. 만료된 인사이트 자동 삭제 함수
CREATE OR REPLACE FUNCTION cleanup_expired_insights()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM reading_insights_memory
  WHERE expires_at < NOW();
END;
$$;

COMMENT ON FUNCTION cleanup_expired_insights IS '만료된 독서 인사이트 메모리 정리 (pg_cron으로 주기적 실행)';

-- 4. 코멘트 추가
COMMENT ON TABLE reading_insights_memory IS 'AI 독서 인사이트 메모리 저장 (12개월 보관 후 자동 삭제)';
COMMENT ON TABLE reading_insights_rate_limit IS '사용자별 인사이트 생성 레이트 제한 추적';
