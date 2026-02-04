-- Add long_review column to books table for storing book reviews
-- Separate from existing 'review' column which is used for short one-line reviews

ALTER TABLE books ADD COLUMN IF NOT EXISTS long_review TEXT;

COMMENT ON COLUMN books.long_review IS '독후감 본문 (AI 생성 또는 직접 작성)';
