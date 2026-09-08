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

- `npm run reset:fixtures` — blocked until Docker Desktop can complete its macOS administrator-authenticated engine initialization.

## Provenance

- Issue: #414
- Branch: `codex/feature/web/1.1.0/BOK-414-browser-fixtures`
- Target: `version/web/1.1.0`
