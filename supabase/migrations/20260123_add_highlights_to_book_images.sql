ALTER TABLE public.book_images
ADD COLUMN IF NOT EXISTS highlights jsonb DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.book_images.highlights IS 'Highlight rectangles: [{id, rect: {x, y, width, height}, color, opacity}]. Normalized 0-1 coords.';
