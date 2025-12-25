-- 푸시 발송 로그 테이블
CREATE TABLE push_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  push_type TEXT NOT NULL,
  book_id UUID,
  title TEXT,
  body TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  is_clicked BOOLEAN DEFAULT false,
  clicked_at TIMESTAMPTZ
);

-- 인덱스 생성
CREATE INDEX idx_push_logs_user_sent ON push_logs(user_id, sent_at DESC);
CREATE INDEX idx_push_logs_clicked ON push_logs(user_id, is_clicked);
CREATE INDEX idx_push_logs_type ON push_logs(push_type);
CREATE INDEX idx_push_logs_sent_at ON push_logs(sent_at DESC);

-- RLS 정책
ALTER TABLE push_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own push logs"
  ON push_logs
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage push_logs"
  ON push_logs
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- 통계 뷰 생성
CREATE OR REPLACE VIEW push_stats_daily AS
SELECT
  DATE(sent_at) as date,
  push_type,
  COUNT(*) as sent_count,
  SUM(CASE WHEN is_clicked THEN 1 ELSE 0 END) as clicked_count,
  ROUND(100.0 * SUM(CASE WHEN is_clicked THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) as ctr
FROM push_logs
GROUP BY DATE(sent_at), push_type
ORDER BY date DESC, push_type;
