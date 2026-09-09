# #414 final verification

Date: 2026-09-09

## Browser and fixture infrastructure

- `npm run test:e2e -- --list` — PASS: Chromium, Firefox and WebKit projects resolve.
- `npm run test:fixtures` — PASS: isolated User A/User B, books, images and secret-scan negative fixture.
- `npm run test:evidence-paths` — PASS: task and visual evidence manifests are scoped, present and digest-checked.
- `npm run test:e2e -- --project=chromium --grep missing-session` — PASS: missing-session surface fails closed.
- `npm run lint` — PASS.
- `npm run typecheck` — PASS.
- `npm test` — PASS: 27 Vitest tests, parity matrix, 59 negative parity fixtures, BLDS parity/negative/SSR contracts.
- `npm run test:e2e -- --project=chromium` — PASS: 5 tests covering ko/en light/dark consumer states and missing-session handling.
- `npm run build` — PASS: 19 generated application routes.
- external `PLAYWRIGHT_BASE_URL` — PASS: non-loopback URL rejected; IPv6 loopback accepted.

## Local reset

- `npm run reset:fixtures` — PASS on the Tailscale-linked `byungsker` MacBook Docker Desktop host using an isolated `book-golas-414-remote` project and ports 55321–55327. The run reset the local database and uploaded `cover.png` to `book-images/user-a/book-a.png` and `book-images/user-b/book-b.png` using the ephemeral local service-role key from `supabase status`.
- The first real reset exposed a Supabase Storage protection error from direct `storage.objects` deletion; removing that redundant seed statement produced the passing reset above. The current MacBook Docker engine remains unavailable while locked.

## Provenance

- Issue: #414
- Branch: `codex/feature/web/1.1.0/BOK-414-browser-fixtures`
- Target: `version/web/1.1.0`
- Plan: `.omo/plans/bookgolas-web-app-parity.md`
