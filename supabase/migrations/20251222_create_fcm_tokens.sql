-- FCM 토큰 저장 테이블 생성
-- 서버에서 푸시 알림을 보내기 위해 사용자별 FCM 토큰 저장

CREATE TABLE IF NOT EXISTS fcm_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  token TEXT NOT NULL,
  device_type TEXT CHECK (device_type IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS (Row Level Security) 활성화
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS 정책: 사용자는 자신의 토큰만 관리 가능
CREATE POLICY "Users can insert own tokens" ON fcm_tokens
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own tokens" ON fcm_tokens
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens" ON fcm_tokens
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens" ON fcm_tokens
  FOR DELETE USING (auth.uid() = user_id);

-- 서비스 역할은 모든 토큰에 접근 가능 (Edge Functions에서 사용)
CREATE POLICY "Service role can access all tokens" ON fcm_tokens
  FOR ALL USING (auth.role() = 'service_role');

-- 인덱스 생성 (사용자별 토큰 조회 최적화)
CREATE INDEX idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- updated_at 자동 업데이트 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fcm_tokens_updated_at
  BEFORE UPDATE ON fcm_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
