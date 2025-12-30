-- Reading Progress History Table
-- Records page updates for tracking reading progress over time

CREATE TABLE IF NOT EXISTS reading_progress_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE NOT NULL,
  page INTEGER NOT NULL CHECK (page >= 0),
  previous_page INTEGER DEFAULT 0 CHECK (previous_page >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_reading_progress_user_book ON reading_progress_history(user_id, book_id, created_at DESC);
CREATE INDEX idx_reading_progress_book_id ON reading_progress_history(book_id);
CREATE INDEX idx_reading_progress_created_at ON reading_progress_history(created_at DESC);

-- RLS (Row Level Security)
ALTER TABLE reading_progress_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can insert own progress" ON reading_progress_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own progress" ON reading_progress_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress" ON reading_progress_history
  FOR DELETE USING (auth.uid() = user_id);
