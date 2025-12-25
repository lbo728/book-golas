-- 푸시 템플릿 테이블: 코드 수정 없이 메시지 변경 가능
CREATE TABLE push_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  body_template TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 기본 템플릿 삽입
INSERT INTO push_templates (type, title, body_template, priority) VALUES
('inactive', '독서를 잊지 마세요! 📚', '{days}일째 독서를 안 했네요. 다시 시작해볼까요?', 10),
('deadline', '목표 완료까지 얼마 안 남았어요! ⏰', '"{bookTitle}" 완독까지 {days}일 남았습니다.', 20),
('progress', '목표 달성까지 조금만 더! 🎯', '"{bookTitle}" {percent}% 완독했습니다. 조금만 더 화이팅!', 30),
('streak', '독서 연속일을 이어가세요! 🔥', '독서 연속일이 {days}일입니다! 오늘도 읽어볼까요?', 40),
('achievement', '목표를 달성했어요! 🎉', '"{bookTitle}" 완독을 축하합니다!', 50);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_push_templates_updated_at
  BEFORE UPDATE ON push_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- RLS 정책 (관리자만 수정 가능, 읽기는 서비스 역할)
ALTER TABLE push_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role can manage push_templates"
  ON push_templates
  FOR ALL
  USING (true)
  WITH CHECK (true);
