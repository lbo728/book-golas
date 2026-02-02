-- Add RPC function for incrementing AI Recall usage
-- This is called from the Flutter app after each AI Recall usage

CREATE OR REPLACE FUNCTION increment_ai_recall_usage(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.users
  SET
    ai_recall_usage_count = COALESCE(ai_recall_usage_count, 0) + 1,
    ai_recall_reset_at = COALESCE(ai_recall_reset_at, date_trunc('month', now())) + interval '1 month'
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
