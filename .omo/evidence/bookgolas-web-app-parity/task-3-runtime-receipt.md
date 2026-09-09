# BOK-413 runtime receipt

- Implementation commits: `fdaccbf2dd97c915ca12953d99f82c7c44d8b5db`, `95216e601b3dd08a5b6db0dee52a86edd19958d6`, `1a49b3d7f749dfffc9cb5a4454cb37849bfe5d6c`
- Runtime: clean isolated Supabase project `book-golas-413-review` on remote Docker host `byungsker-docker`.
- Review worktree: `/private/tmp/bookgolas-review-413`.

## Runtime preparation

- Removed only the prior `book-golas-413-review` Supabase data volumes after an Auth ownership failure from the stale backup volume.
- `supabase start --workdir /tmp/bookgolas-review-413-runtime`: exit 0.
- `supabase db reset --workdir /tmp/bookgolas-review-413-runtime --yes`: exit 0; all migrations including the final ownership/progress migration applied.

## Commands and observed results

- `npm ci --prefix web`: exit 0.
- `npm --prefix web run test:status-migration`: exit 0; all documented legacy aliases mapped and unknown `mystery` status rejected with the typed migration error.
- `npm --prefix web run test:rls`: exit 0; owner isolation, deleted-at filtering, and reading-session parent ownership passed.
- `npm --prefix web run test:rls -- --grep user-b-isolation`: exit 0.
- `npm --prefix web run test:progress-rpc`: exit 0; atomic write, stale conflict, idempotency, backward edit, completion, and owner boundary passed.
- `npm --prefix web run typecheck`: exit 0.
- `npm --prefix web run lint`: exit 0.
- `npm --prefix web test`: exit 0; 8 Vitest files and 71 tests, including the action-level RPC integration assertions, parity matrix, 59 parity negative fixtures, BLDS React parity, BLDS negative, and SSR state contracts passed.
- `task-3-bookgolas-web-app-parity.sql` via `psql -v ON_ERROR_STOP=1`: exit 0; RED, GREEN, SURFACE, and CLEANUP phases observed. Cleanup counts were books=0, progress=0, requests=0.
- Security surface query: RPC `search_path=pg_catalog, pg_temp`; authenticated schema CREATE=false; history UPDATE=false/DELETE=false.

## SHA-256 of implementation files

- `234ad69ce8b980058ed85821cd42745846524a1da6317f4b9a4fd80a6555f055`  .omo/evidence/bookgolas-web-app-parity/task-3-bookgolas-web-app-parity.sql
- `0f0893dbef8d91cec43e851ef62840e203a33c80a4311ad6b4e2a50501562fbb`  docs/guides/reading-progress-contract.md
- `00df273a721891e73a39dd708ad32ab7004c616fce92609cbd2398ceb1ffd57f`  supabase/migrations/20260909163608_harden_ownership_and_progress_contract.sql
- `be4da1a0187941b4dda5d60b595165af31e2f041180825de023337ca7472c1cc`  web/package.json
- `5a6c6f56bcf6db9f92e7894a96e9597dae3e026ceffed36d721df0c4f024faca`  web/scripts/test-progress-rpc.mjs
- `c179949278638aa3fe36064eedfac9ba3cb89051045baa20352ed280ce058a79`  web/scripts/test-rls.mjs
- `796d19cec06873dcfa14a849388f4f1e0a05816e3b3618f51859100184c79627`  web/scripts/test-status-migration.mjs
- `7a32d256ff697280dc33f99f19407a5255c8f2967639f1a2dcf0747461601405`  web/src/app/actions/reading-progress.ts
- `618c69c01e1e8b031cbe5092ee361765f6e9beec06ee932fae7f5c3a2ccf45e7`  web/src/app/actions/reading-progress.test.ts
- `243b41003bb0b532d26038352bf9f76dd4eadf3eb1cbb42406e9cf336a8f4502`  web/src/components/consumer/progress-updater.tsx
