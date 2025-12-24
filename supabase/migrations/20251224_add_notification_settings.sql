-- 사용자별 알림 설정 컬럼 추가
-- preferred_hour: 알림 받을 시간 (0-23, KST 기준)
-- notification_enabled: 알림 활성화 여부

ALTER TABLE fcm_tokens
ADD COLUMN IF NOT EXISTS preferred_hour INTEGER DEFAULT 9 CHECK (preferred_hour >= 0 AND preferred_hour <= 23),
ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN DEFAULT true;

-- 알림 시간대별 조회를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_preferred_hour ON fcm_tokens(preferred_hour);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_notification_enabled ON fcm_tokens(notification_enabled);

-- 복합 인덱스 (활성화된 사용자 중 특정 시간대 조회)
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_notification_filter
ON fcm_tokens(notification_enabled, preferred_hour)
WHERE notification_enabled = true;

COMMENT ON COLUMN fcm_tokens.preferred_hour IS '알림 받을 시간 (0-23, KST 기준). 기본값 9 (오전 9시)';
COMMENT ON COLUMN fcm_tokens.notification_enabled IS '푸시 알림 활성화 여부. 기본값 true';
