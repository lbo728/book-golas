\set ON_ERROR_STOP on
\echo 'RED: pre-migration acceptance observations'
SELECT 'RED' AS phase, 'test:rls exited 3 because authenticated child-table access was not granted' AS observation;
SELECT 'RED' AS phase, 'test:progress-rpc exited 1 because update_reading_progress did not exist' AS observation;
\echo 'GREEN: schema and RPC contract'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.books'::regclass
      AND conname = 'books_status_check'
  ) THEN
    RAISE EXCEPTION 'books_status_check is missing';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_class
    WHERE oid = 'public.reading_progress_requests'::regclass
      AND relrowsecurity
  ) THEN
    RAISE EXCEPTION 'reading_progress_requests RLS is missing';
  END IF;
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc
    WHERE oid = 'public.update_reading_progress(uuid,integer,integer,uuid,integer)'::regprocedure
      AND prosecdef
  ) THEN
    RAISE EXCEPTION 'secured progress RPC is missing';
  END IF;
END;
$$;
SELECT 'GREEN' AS phase, proname, pg_get_function_identity_arguments(oid) AS arguments, prosecdef AS security_definer
FROM pg_proc
WHERE oid = 'public.update_reading_progress(uuid,integer,integer,uuid,integer)'::regprocedure;
\echo 'SURFACE: owner and lifecycle boundaries'
SELECT 'SURFACE' AS phase, relname, relrowsecurity
FROM pg_class
WHERE oid IN ('public.books'::regclass, 'public.book_images'::regclass, 'public.reading_progress_history'::regclass, 'public.reading_sessions'::regclass)
ORDER BY relname;
SELECT 'SURFACE' AS phase, policyname, tablename
FROM pg_policies
WHERE schemaname = 'public'
  AND policyname IN (
    'Users can view images for their own active books',
    'Users can insert images for their own active books',
    'Users can view progress for their own active books',
    'Users can insert progress for their own active books',
    'Users can view sessions for their own active books',
    'Users can insert sessions for their own active books'
  )
ORDER BY tablename, policyname;
\echo 'CLEANUP: fixture state'
SELECT 'CLEANUP' AS phase,
  (SELECT count(*) FROM public.books WHERE id IN (
    '00000000-0000-4000-8000-000000002001',
    '00000000-0000-4000-8000-000000002002',
    '00000000-0000-4000-8000-000000002003'
  )) AS books_fixture_rows,
  (SELECT count(*) FROM public.reading_progress_history WHERE book_id = '00000000-0000-4000-8000-000000002001') AS progress_fixture_rows,
  (SELECT count(*) FROM public.reading_progress_requests WHERE book_id = '00000000-0000-4000-8000-000000002001') AS request_fixture_rows;
