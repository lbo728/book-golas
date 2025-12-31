-- Add daily_target_pages column to books table
ALTER TABLE books
ADD COLUMN IF NOT EXISTS daily_target_pages INTEGER;

-- Add comment for documentation
COMMENT ON COLUMN books.daily_target_pages IS 'User-set daily page reading target for this book';
