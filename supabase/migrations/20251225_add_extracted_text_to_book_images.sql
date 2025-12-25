-- Add extracted_text column for OCR text storage
ALTER TABLE book_images
ADD COLUMN IF NOT EXISTS extracted_text TEXT;

-- Add comment for documentation
COMMENT ON COLUMN book_images.extracted_text IS 'OCR로 추출된 텍스트 (Google Cloud Vision API)';
