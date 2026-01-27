-- Make recall_search_history.book_id nullable for global search
ALTER TABLE recall_search_history ALTER COLUMN book_id DROP NOT NULL;
