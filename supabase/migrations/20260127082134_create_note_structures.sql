-- Migration: Create Note Structures Table
-- Description: 마인드맵 JSON 저장을 위한 note_structures 테이블 생성
-- Issue: BYU-292

-- 1. note_structures 테이블 생성
CREATE TABLE IF NOT EXISTS note_structures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
  structure_json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

-- 2. 사용자별 빠른 조회 인덱스
CREATE INDEX IF NOT EXISTS idx_note_structures_user_book 
ON note_structures(user_id, book_id);

-- 3. RLS 정책 활성화
ALTER TABLE note_structures ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책: 사용자는 자신의 구조만 관리 가능
CREATE POLICY "Users can manage own structures"
  ON note_structures FOR ALL
  USING (auth.uid() = user_id);

-- 5. 코멘트 추가
COMMENT ON TABLE note_structures IS '마인드맵 구조 저장 (노드, 연결, 클러스터)';
COMMENT ON COLUMN note_structures.structure_json IS '마인드맵 JSON 구조 (nodes, connections, clusters)';
