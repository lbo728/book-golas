# BOK-413 runtime receipt

- Implementation commit: `fdaccbf2dd97c915ca12953d99f82c7c44d8b5db`
- Runtime: isolated Supabase project `book-golas-413-review` on remote Docker host `byungsker-docker`.
- Review worktree: `/private/tmp/bookgolas-review-413`.

## Commands and observed results

- `supabase db reset --workdir /tmp/bookgolas-review-413-runtime --yes`: exit 0; final migration applied.
- `npm ci --prefix web`: exit 0.
- `npm --prefix web run test:status-migration`: exit 0; legacy status upgrade fixture and unknown-value guard passed.
- `npm --prefix web run test:rls`: exit 0; owner isolation, deleted-at filtering, and reading-session parent ownership passed.
- `npm --prefix web run test:rls -- --grep user-b-isolation`: exit 0.
- `npm --prefix web run test:progress-rpc`: exit 0; atomic write, stale conflict, idempotency, backward edit, completion, and owner boundary passed.
- `npm --prefix web run typecheck`: exit 0.
- `npm --prefix web run lint`: exit 0.
- `npm --prefix web test`: exit 0; 8 Vitest files and 71 tests, parity matrix, 59 parity negative fixtures, BLDS React parity, BLDS negative, and SSR state contracts passed.
- `task-3-bookgolas-web-app-parity.sql` via `psql -v ON_ERROR_STOP=1`: exit 0; RED, GREEN, SURFACE, and CLEANUP phases observed. Cleanup counts were books=0, progress=0, requests=0.
- Security surface query: RPC `search_path=pg_catalog, pg_temp`; authenticated schema CREATE=false; history UPDATE=false/DELETE=false.

## SHA-256 of implementation files

- `234ad69ce8b980058ed85821cd42745846524a1da6317f4b9a4fd80a6555f055`  .omo/evidence/bookgolas-web-app-parity/task-3-bookgolas-web-app-parity.sql
- `0f0893dbef8d91cec43e851ef62840e203a33c80a4311ad6b4e2a50501562fbb`  docs/guides/reading-progress-contract.md
- `00df273a721891e73a39dd708ad32ab7004c616fce92609cbd2398ceb1ffd57f`  supabase/migrations/20260909163608_harden_ownership_and_progress_contract.sql
- `be4da1a0187941b4dda5d60b595165af31e2f041180825de023337ca7472c1cc`  web/package.json
- `5a6c6f56bcf6db9f92e7894a96e9597dae3e026ceffed36d721df0c4f024faca`  web/scripts/test-progress-rpc.mjs
- `c179949278638aa3fe36064eedfac9ba3cb89051045baa20352ed280ce058a79`  web/scripts/test-rls.mjs
- `c180f76eab179664d506d4b5eeb03ad6988e3b9ac503aed323e66caea9c28fa7`  web/scripts/test-status-migration.mjs
