-- BYU-145: 독서 상태 관리 필드 추가

-- 1. 우선순위 필드 (1=긴급, 2=높음, 3=보통, 4=낮음)
ALTER TABLE books
ADD COLUMN priority INT DEFAULT NULL
CHECK (priority IS NULL OR (priority >= 1 AND priority <= 4));

-- 2. 중단일 필드 (다시 읽을 책용)
ALTER TABLE books
ADD COLUMN paused_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 3. 예정 시작일 필드 (읽을 예정 책용)
ALTER TABLE books
ADD COLUMN planned_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 4. Soft Delete 필드
ALTER TABLE books
ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- 인덱스 추가 (성능 최적화)
CREATE INDEX idx_books_status_priority ON books(status, priority) 
  WHERE priority IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX idx_books_paused_at ON books(paused_at) 
  WHERE paused_at IS NOT NULL AND deleted_at IS NULL;

CREATE INDEX idx_books_deleted_at ON books(deleted_at) 
  WHERE deleted_at IS NOT NULL;

CREATE INDEX idx_books_user_status_deleted ON books(user_id, status, deleted_at);

COMMENT ON COLUMN books.priority IS '우선순위 (1=긴급, 2=높음, 3=보통, 4=낮음)';
COMMENT ON COLUMN books.paused_at IS '독서 중단 일시 (will_retry 상태로 전환된 시점)';
COMMENT ON COLUMN books.planned_start_date IS '독서 시작 예정일 (planned 상태일 때)';
COMMENT ON COLUMN books.deleted_at IS 'Soft Delete 타임스탬프';
