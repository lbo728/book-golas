-- BYU-178: 독서 상태 기능 개선
-- 1. books 테이블에 신규 필드 추가 (장르, 출판사, 별점, 한줄평, 독후감 링크, 알라딘 URL)
-- 2. reading_goals 테이블 생성 (연간 독서 목표)

-- =====================================================
-- 1. Books 테이블 필드 추가
-- =====================================================

-- 장르 (Aladin API categoryName에서 파싱)
ALTER TABLE books ADD COLUMN IF NOT EXISTS genre TEXT;

-- 출판사 (Aladin API publisher)
ALTER TABLE books ADD COLUMN IF NOT EXISTS publisher TEXT;

-- ISBN (Aladin API isbn13)
ALTER TABLE books ADD COLUMN IF NOT EXISTS isbn TEXT;

-- 별점 (1-5)
ALTER TABLE books ADD COLUMN IF NOT EXISTS rating INT;
ALTER TABLE books ADD CONSTRAINT books_rating_check 
  CHECK (rating IS NULL OR (rating >= 1 AND rating <= 5));

-- 한줄평
ALTER TABLE books ADD COLUMN IF NOT EXISTS review TEXT;

-- 독후감 링크 (블로그, 노션 등)
ALTER TABLE books ADD COLUMN IF NOT EXISTS review_link TEXT;

-- 알라딘 도서 링크
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_url TEXT;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_books_genre 
  ON books(genre) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_books_rating 
  ON books(rating) WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_books_isbn 
  ON books(isbn) WHERE deleted_at IS NULL;

-- =====================================================
-- 2. Reading Goals 테이블 생성
-- =====================================================

CREATE TABLE IF NOT EXISTS reading_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  year INT NOT NULL,
  target_books INT NOT NULL CHECK (target_books > 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, year)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_reading_goals_user_year 
  ON reading_goals(user_id, year);

-- RLS 정책
ALTER TABLE reading_goals ENABLE ROW LEVEL SECURITY;

-- SELECT: 자신의 목표만 조회 가능
CREATE POLICY "Users can view own goals"
  ON reading_goals FOR SELECT
  USING (auth.uid() = user_id);

-- INSERT: 자신의 목표만 추가 가능
CREATE POLICY "Users can insert own goals"
  ON reading_goals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: 자신의 목표만 수정 가능
CREATE POLICY "Users can update own goals"
  ON reading_goals FOR UPDATE
  USING (auth.uid() = user_id);

-- DELETE: 자신의 목표만 삭제 가능
CREATE POLICY "Users can delete own goals"
  ON reading_goals FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 3. 트리거: updated_at 자동 갱신
-- =====================================================

CREATE OR REPLACE FUNCTION update_reading_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_reading_goals_updated_at ON reading_goals;
CREATE TRIGGER trigger_reading_goals_updated_at
  BEFORE UPDATE ON reading_goals
  FOR EACH ROW
  EXECUTE FUNCTION update_reading_goals_updated_at();
