# Task 2 runtime transcript

Target-Delivery-Unit: web
Target-Version: 1.1.0
Delivery-Profile: web-release-train

Tested implementation commit: `1408c69d8f330d69b577a396592e049a08eeac2b`

## RED

Command: `npm run test:product-contracts`

Context: the permanent adversarial route test was present, but the route helper had not yet validated `bookId` through `BookIdSchema`.

Observed: exit 1; `contracts.test.ts` reported 1 failed and 40 passed. `consumerRoutes.book("ko", "../account")` did not throw.

## GREEN

Command: `npm run test:product-contracts`

Observed: exit 0; 2 files and 41 tests passed.

Command: `npm run test:product-contracts -- --grep cross-user-request`

Observed: exit 0; 1 targeted test passed and 40 tests were skipped.

Command: `npm test`

Observed: exit 0; 8 files and 68 tests passed. The parity matrix, 59 negative fixtures, BLDS React parity, BLDS negative fixture and SSR state checks passed.

## SURFACE

Command: `npm run build`

Observed: exit 0; Next production compilation completed and 19 static pages were generated.

The changed surface is the typed contract boundary and its build integration. No UI component implementation was changed, so browser interaction is not applicable to this task.

## CLEANUP

Commands: `npm run typecheck`, `npm run lint`, `npm run test:evidence-paths`, `git diff --check`.

Observed: all exit 0. The checksum manifest validated the task evidence files, and no debug statements, temporary fixtures or inspector processes remained.

Plan: .omo/plans/bookgolas-web-app-parity.md
