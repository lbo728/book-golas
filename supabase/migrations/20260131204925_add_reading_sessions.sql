-- Create reading_sessions table for tracking reading sessions
CREATE TABLE IF NOT EXISTS public.reading_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  book_id uuid NOT NULL REFERENCES public.books(id),
  started_at timestamptz NOT NULL,
  ended_at timestamptz,
  duration_seconds integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Add total_reading_seconds column to books table
ALTER TABLE public.books ADD COLUMN IF NOT EXISTS total_reading_seconds integer DEFAULT 0;

-- Enable RLS on reading_sessions
ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own reading sessions
CREATE POLICY "Users can view own reading sessions" ON public.reading_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own reading sessions
CREATE POLICY "Users can insert own reading sessions" ON public.reading_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own reading sessions
CREATE POLICY "Users can update own reading sessions" ON public.reading_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policy: Users can delete their own reading sessions
CREATE POLICY "Users can delete own reading sessions" ON public.reading_sessions
  FOR DELETE USING (auth.uid() = user_id);
