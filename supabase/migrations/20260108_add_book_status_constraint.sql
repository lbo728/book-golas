-- BYU-193: books.status 컬럼에 CHECK 제약조건 추가
-- 가능한 값: 'planned', 'reading', 'completed', 'will_retry'

-- 1. 기존 null 값을 'reading'으로 업데이트
UPDATE books
SET status = 'reading'
WHERE status IS NULL;

-- 2. 완독한 책 상태 업데이트 (current_page >= total_pages이고 status가 reading인 경우)
UPDATE books
SET status = 'completed'
WHERE current_page >= total_pages
  AND total_pages > 0
  AND status = 'reading';

-- 3. status 컬럼을 NOT NULL로 변경하고 기본값 설정
ALTER TABLE books
ALTER COLUMN status SET NOT NULL,
ALTER COLUMN status SET DEFAULT 'reading';

-- 4. CHECK 제약조건 추가
ALTER TABLE books
ADD CONSTRAINT books_status_check
CHECK (status IN ('planned', 'reading', 'completed', 'will_retry'));
