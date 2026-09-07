# Bookgolas Web 1.1.0 Consumer Parity Matrix

Target-Delivery-Unit: web
Target-Version: 1.1.0
Delivery-Profile: web-release-train

## Purpose

This document freezes the native-to-Web contract for the authenticated Bookgolas consumer product. The native Flutter app and the cross-platform BLab contract are the reference. The marketing site, legal pages and admin console are separate surfaces and are not evidence of consumer parity.

The machine-checkable source of truth is consumer-parity-ledger.json. Every route, overlay and capability entry has a native source, one Web disposition, a current or planned Web target, all required state dispositions, user-facing actions and an owning issue. The independent native expected-surface inventory in native-consumer-surface-inventory.json makes omitted native routes, overlays and actions fail validation.

The ledger records the current repository state, not a claim that planned routes already work. A complete status requires independent data and browser evidence; no entry is marked complete in this initial freeze. Deep-link mappings are machine-checked in the ledger as well as summarized below.

## Parity rule

For every supported feature, Web must match the app in:

- visual language, BLab tokens, typography, spacing, surfaces and component anatomy;
- information hierarchy, localized copy and navigation semantics;
- actions, validation, state transitions, loading, empty, error, retry, consent and quota outcomes;
- keyboard, screen-reader, focus, reduced-motion and pointer behavior;
- user ownership, persistence, deep-link recovery and safe unauthorized handling.

Responsive Web geometry may adapt to viewport constraints. It may not introduce a different product behavior, information hierarchy, state model or feature promise. Every intentional difference must be recorded as a parity-matrix exception before implementation.

Web 1.1.0 uses the online-core policy. Offline behavior is either explicitly bounded and tested or shown as unavailable. Native-only capabilities are listed below instead of being silently dropped.

## Canonical consumer routes

All consumer routes support the ko and en locale contract. Existing Web files are marked partial until complete native behavior is verified.

| Native surface | Canonical Web URL | Current Web evidence | Status | Owner |
| --- | --- | --- | --- | --- |
| Sign in | /{locale}/auth/sign-in | web/src/app/[locale]/auth/sign-in/page.tsx | partial | #423 |
| Account creation | /{locale}/auth/sign-up | web/src/app/[locale]/auth/sign-up/page.tsx | partial | #423 |
| Password recovery | /{locale}/auth/reset-password | web/src/app/[locale]/auth/reset-password/page.tsx | partial | #423 |
| Terms WebView | /{locale}/terms | web/src/app/terms/page.tsx | partial | #444 |
| Onboarding | /{locale}/onboarding | not implemented | planned | #426 |
| Home and reading status | /{locale}/home | web/src/app/[locale]/home/page.tsx | partial | #429 |
| My Library | /{locale}/library | not implemented | planned | #430 |
| Reading statistics | /{locale}/stats | not implemented | planned | #440 |
| Calendar | /{locale}/calendar | not implemented | planned | #439 |
| My Page and settings | /{locale}/account | not implemented | planned | #444 |
| Native book-list route | /{locale}/book-list | not implemented | planned | #430 |
| Search and add book | /{locale}/books/new | not implemented | planned | #428/#431 |
| Book detail | /{locale}/books/{bookId} | web/src/app/[locale]/books/[bookId]/page.tsx | partial | #433 |
| Reading progress | /{locale}/reading/{bookId} | web/src/app/[locale]/reading/[bookId]/page.tsx | partial | #434 |
| Book review editor | /{locale}/books/{bookId}/review | not implemented | planned | #437 |
| Note-structure mind map | /{locale}/books/{bookId}/mind-map | not implemented | planned | #442 |
| Barcode scanner | /{locale}/books/scan | not implemented | planned browser equivalent | #428 |
| Subscription entry | /{locale}/subscription | intentionally disabled | disabled | #444 |
| Privacy and consent | /{locale}/privacy | web/src/app/privacy/page.tsx | partial | #444 |

## Shared shell and action contract

The native MainScreen has five persistent tabs: Home, My Library, Reading Statistics, Calendar and My Page. Repeated selection of Home cycles its status view; repeated selection of Reading Statistics cycles its section. The bottom-bar search affordance opens book search or AI Recall search depending on the selected mode.

| Native behavior | Web requirement | Owning issue |
| --- | --- | --- |
| Five-tab navigation | Preserve tab order, selected state, keyboard order and deep-linkable destination | #425 |
| Home status cycle | Preserve reading, planned, completed and paused state surfaces | #429 |
| Statistics section cycle | Preserve overview, analysis and activity sections plus annual, monthly, weekly and custom filters | #440 |
| Book status model | Preserve planned, reading, completed and will_retry semantics | #429/#431 |
| Search mode menu | Preserve book search and AI record search as separate actions | #428/#441 |
| Locale | Every consumer state and action has Korean and English copy | #422 |
| Auth recovery | Preserve locale and validate the next path before returning | #427 |

The ledger contains the action-level contract for each screen and overlay, including destructive confirmation, cancel, retry, permission, consent and quota outcomes.

## Overlay and sheet inventory

The native app uses sheets, dialogs, context menus and full-screen overlays heavily. The Web implementation may use an accessible dialog, sheet or route-preserving overlay, but it must keep the same action result and state transitions.

The complete inventory is in the ledger. It includes:

- navigation and discovery: search mode menu, Global Recall, book Recall, record detail, source detail, bookstore selection, recommendation actions and reading-book selection;
- statistics and calendar: day detail, reading goal and custom date range;
- book and reading flows: reading management, pause/delete confirmations, book info, full title, page update, reading timer, daily goal, daily target, target date, planned-book editor, completion and review prompt;
- book detail metadata: external review-link editor, mind-map leaf detail and mind-map cluster detail;
- private media and OCR: image source, image replacement, memorable-page capture, existing image, extracted text, full text, OCR quota and full-screen image viewer;
- account and feedback: review exit/save confirmations, password change, account deletion, notification time picker, disabled Pro state and floating timer;
- shared BLDS primitives: context menu and search overlay.

Every listed overlay has an action owner and one of the state profiles in the ledger. There are no anonymous modal or sheet entries.

## Native-only and browser-equivalent capabilities

| Capability | Native evidence | Web disposition | Status | Owner |
| --- | --- | --- | --- | --- |
| iOS home widgets | WidgetDataService, HomeWidget and widget deep links | No Web OS widget; ordinary HTTPS deep links remain supported | unavailable | #445 |
| Siri and App Shortcuts | BookgolasShortcuts.swift, AppDelegate.swift and Info.plist implement three native shortcuts | No Web OS shortcut; ordinary HTTPS destinations remain supported | unavailable | #416 |
| FCM and local notifications | fcm_service.dart and notification settings | Browser Push API with permission and delivery differences | planned equivalent | #445 |
| Camera, barcode, document scan and OCR | scanner, document scan and OCR utilities | Browser permission plus input/upload fallback | planned equivalent | #428/#435 |
| Native share sheet | BookShareService and share cards | Web Share API plus clipboard/download fallback | planned equivalent | #443 |
| RevenueCat subscriptions | Native service exists; paid flag defaults off | Purchase, restore, upgrade and customer center disabled | disabled | #444 |
| Offline mutation | Local cache/draft and widget behavior only | Online-core boundary; no unverified offline writes | partial boundary | #447 |
| Native deep links | bookgolas://book/... parser | Locale-preserving HTTPS routes and safe next paths | partial equivalent | #427 |

## State profiles

Every ledger entry points to a profile. All profiles explicitly define:

| State | Required question |
| --- | --- |
| Loading | What progress or skeleton is shown, and how are duplicate actions prevented? |
| Empty | What does the user see when there is no data or input? |
| Error | What localized retry or safe fallback is available? |
| Unauthorized | How does the surface return to sign-in without exposing data? |
| Consent | Which provider, AI, notification or browser permission is required? |
| Quota | What is disabled or explained without Web billing? |
| Offline | Which behavior is proven, and where is the online-core boundary shown? |

The exact profile text is in the ledger. A missing profile key is a validation failure.

## Canonical deep-link mapping

| Native link | Canonical Web destination |
| --- | --- |
| bookgolas://book/search | /{locale}/books/new |
| bookgolas://book/detail/{bookId} | /{locale}/books/{bookId} |
| bookgolas://book/record/{bookId} | /{locale}/books/{bookId}?tab=record |
| bookgolas://book/scan/{bookId} | /{locale}/books/{bookId}?scan=1 |
| Auth callback with next | Validated /{locale}/... consumer path, otherwise /{locale}/home |

## Validation

From web/:

~~~bash
npm run test:parity-matrix
npm run test:parity-matrix -- --fixture missing-disposition
npm run test:parity-matrix -- --fixture duplicate-canonical-url
npm run test:parity-matrix -- --fixture missing-error-state
npm run test:parity-matrix -- --fixture missing-required-state
npm run test:parity-matrix -- --fixture complete-without-evidence
npm run test:parity-matrix -- --fixture complete-with-invalid-evidence
npm run test:parity-matrix -- --fixture invalid-native-boundary
npm run test:parity-matrix -- --fixture missing-deep-link
npm run test:parity-matrix -- --fixture invalid-deep-link-target
npm run test:parity-matrix -- --fixture invalid-deep-link-source
npm run test:parity-matrix -- --fixture missing-native-overlay
npm run test:parity-matrix -- --fixture missing-native-action
npm run test:parity-matrix -- --fixture complete-with-fabricated-evidence
npm run test:parity-matrix -- --fixture invalid-billing-route
npm run test:parity-matrix -- --fixture invalid-billing-overlay
npm run test:parity-matrix -- --fixture invalid-billing-claim
npm run test:parity-matrix -- --fixture complete-with-aliased-evidence
npm run test:parity-matrix -- --fixture unsafe-source-reference
~~~

The first command must exit 0. Every fixture command must fail, proving the checker rejects missing dispositions, duplicate canonical URLs, missing error-state entries, complete status without independent data/browser evidence, fabricated or alias-based evidence, unsafe source paths, invalid native-only boundaries, wrong or unallowlisted deep links, omitted native surfaces/actions and accidental Web billing activation. Complete evidence is bound to the exact current Git commit and must use independent, repository-contained source and artifact paths. `npm test` runs both the positive checker and the complete negative-fixture suite so the ledger cannot bypass the Web quality gate. The checker further rejects missing actions, missing evidence owners, missing deep links and incomplete native-only capability coverage.

## Evidence sources

- Native bootstrap and five-tab shell: app/lib/main.dart
- Native route constants: app/lib/routing/app_router.dart
- Native screens, tabs, sheets and dialogs: app/lib/ui/
- Native models and status values: app/lib/domain/models/
- Native provider, notification, widget and deep-link behavior: app/lib/data/services/
- Native iOS widgets and App Shortcuts: app/ios/BookgolasWidget/BookgolasWidget.swift, app/ios/Runner/BookgolasShortcuts.swift, app/ios/Runner/AppDelegate.swift, app/ios/Runner/Info.plist
- Native feature flags: app/lib/config/feature_flags.dart
- Native localization contract: app/lib/l10n/app_ko.arb and app/lib/l10n/app_en.arb
- Existing Web routes and states: web/src/app/
- Existing Web consumer adapters: web/src/components/consumer/ and web/src/lib/consumer/
- BLDS public contract: blab_design_system repository and BLDS issue 12
- Independent native expected-surface inventory: web/docs/native-consumer-surface-inventory.json

Plan: .omo/plans/bookgolas-web-app-parity.md
