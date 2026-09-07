import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const ledgerPath = path.resolve(scriptDirectory, "../docs/consumer-parity-ledger.json");
const inventoryPath = path.resolve(scriptDirectory, "../docs/native-consumer-surface-inventory.json");
const repositoryRoot = path.resolve(scriptDirectory, "../..");
const ledger = JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
const nativeInventory = JSON.parse(fs.readFileSync(inventoryPath, "utf8"));
let currentCommit = "";
try {
  currentCommit = execFileSync("git", ["rev-parse", "HEAD"], {
    cwd: repositoryRoot,
    encoding: "utf8",
  }).trim();
} catch {
  currentCommit = "";
}
const failures = [];
const expectedStates = [
  "loading",
  "empty",
  "error",
  "unauthorized",
  "consent",
  "quota",
  "offline",
];
const requiredStates = new Set(expectedStates);
const expectedStateProfiles = [
  "default",
  "auth",
  "onboarding",
  "browser-equivalent",
  "native-only",
  "disabled",
];
const allowedWebDispositions = new Set([
  "route",
  "component",
  "browser-equivalent",
  "disabled",
  "explicit-unavailability",
]);
const allowedStatuses = new Set([
  "partial",
  "planned",
  "unavailable",
  "disabled",
  "complete",
]);
const allowedEvidenceKinds = new Set(["data", "browser"]);
const requiredDeepLinkMappings = new Map([
  ["bookgolas://book/search", "/{locale}/books/new"],
  ["bookgolas://book/detail/{bookId}", "/{locale}/books/{bookId}"],
  ["bookgolas://book/record/{bookId}", "/{locale}/books/{bookId}?tab=record"],
  ["bookgolas://book/scan/{bookId}", "/{locale}/books/{bookId}?scan=1"],
  ["Auth callback with next", "/{locale}/auth/sign-in?next={validatedPath}"],
]);
const allowedDeepLinkKinds = new Set(["native-custom-scheme", "auth-return"]);
const nativeCapabilityRules = {
  "ios-home-widget": { disposition: "explicit-unavailability", status: "unavailable" },
  "siri-app-shortcuts": { disposition: "explicit-unavailability", status: "unavailable" },
  "native-push": { disposition: "browser-equivalent", status: "planned" },
  "camera-and-ocr": { disposition: "browser-equivalent", status: "planned" },
  "share-sheet": { disposition: "browser-equivalent", status: "planned" },
  subscriptions: { disposition: "disabled", status: "disabled" },
  "offline-boundary": { disposition: "browser-equivalent", status: "partial" },
  "deep-links": { disposition: "browser-equivalent", status: "partial" },
};
const requiredDeliveryDependencies = {
  parity_matrix: "#416",
  blds_react_next: "#453",
  shared_web_primitives: "#421",
  blds_package: "blab_design_system#12",
};
const requiredNativeSurfaceIds = {
  routes: [
    "auth-login",
    "auth-sign-up",
    "auth-password-recovery",
    "legal-terms",
    "onboarding",
    "home",
    "library",
    "reading-stats",
    "calendar",
    "account",
    "legacy-book-list",
    "book-search-add",
    "book-detail",
    "reading-progress",
    "book-review",
    "mind-map",
    "barcode-scanner",
    "subscription",
    "privacy",
  ],
  overlays: [
    "search-mode-menu",
    "global-recall-search",
    "recall-search",
    "record-detail",
    "source-detail",
    "calendar-day-detail",
    "reading-goal",
    "date-range-picker",
    "bookstore-select",
    "recommendation-action",
    "reading-books-selection",
    "reading-management",
    "pause-reading-confirmation",
    "delete-confirmation",
    "batch-delete-confirmation",
    "book-info",
    "full-title",
    "image-source",
    "image-replace-options",
    "replace-image-confirmation",
    "add-memorable-page",
    "existing-image",
    "extracted-text",
    "full-text-view",
    "page-update",
    "reading-timer",
    "today-goal",
    "daily-target",
    "daily-target-confirm",
    "update-target-date",
    "edit-planned-book",
    "book-completion",
    "book-review-prompt",
    "review-exit-confirmation",
    "review-save-complete",
    "password-change",
    "delete-account-confirmation",
    "notification-time-picker",
    "ocr-limit",
    "pro-features",
    "floating-timer",
    "schedule-change",
    "calendar-month-picker",
    "clear-ai-memory-confirmation",
    "mind-map-leaf-detail",
    "mind-map-cluster-detail",
    "review-link-editor",
    "context-menu",
    "search-overlay",
    "full-screen-image",
  ],
  native_only_capabilities: [
    "ios-home-widget",
    "siri-app-shortcuts",
    "native-push",
    "camera-and-ocr",
    "share-sheet",
    "subscriptions",
    "offline-boundary",
    "deep-links",
  ],
};
const requiredNativeActionIds = {
  routes: {
    "auth-login": "email-sign-in|google-sign-in|apple-sign-in|open-sign-up|open-password-recovery|resend-verification",
    "auth-sign-up": "create-account|confirm-password|open-sign-in|verification-outcome",
    "auth-password-recovery": "request-reset|set-new-password|return-to-sign-in",
    "legal-terms": "read-terms|return-to-account",
    onboarding: "advance-onboarding|complete-onboarding",
    home: "switch-reading-status-tab|toggle-all-books|open-book-detail|refresh-books|open-search-mode",
    library: "library-reading-tab|library-review-tab|library-record-tab|library-global-recall",
    "reading-stats": "stats-overview|stats-analysis|stats-activity|stats-set-goal|stats-share",
    calendar: "change-calendar-month|filter-calendar|open-calendar-day",
    account: "edit-profile|change-language-theme|manage-notifications|change-password|open-legal|sign-out|delete-account",
    "legacy-book-list": "filter-book-list|refresh-book-list|open-list-book-detail",
    "book-search-add": "search-book|isbn-search|scan-isbn|select-reading-status|set-schedule-priority|save-book",
    "book-detail": "switch-detail-tabs|update-progress|manage-reading|set-reading-target|add-memorable-page|open-recall|open-reading-timer|open-review|open-aladin-book-link|open-existing-review-link|open-review-link-editor|resume-reading|start-planned-reading",
    "reading-progress": "update-page|record-history|start-timer|return-to-book",
    "book-review": "edit-review|generate-ai-draft|save-review|discard-review",
    "mind-map": "view-mind-map|regenerate-mind-map|retry-mind-map",
    "barcode-scanner": "request-camera|capture-isbn|use-manual-isbn",
    subscription: "show-disabled-subscription",
    privacy: "read-privacy|manage-consent",
  },
  overlays: {
    "search-mode-menu": "choose-book-search|choose-ai-record-search",
    "global-recall-search": "search-global-records|open-global-record",
    "recall-search": "search-book-records|load-recent-recall|clear-recall-history",
    "record-detail": "view-record|open-source",
    "source-detail": "view-source|close-source",
    "calendar-day-detail": "view-day-activity|open-day-book",
    "reading-goal": "set-yearly-goal|save-goal",
    "date-range-picker": "choose-date-range|cancel-date-range",
    "bookstore-select": "choose-new-bookstore|choose-used-bookstore",
    "recommendation-action": "open-recommendation|add-recommendation",
    "reading-books-selection": "select-reading-book|open-selected-book",
    "reading-management": "pause-reading|delete-book|cancel-reading-management",
    "pause-reading-confirmation": "confirm-pause|cancel-pause",
    "delete-confirmation": "confirm-delete|cancel-delete",
    "batch-delete-confirmation": "confirm-batch-delete|cancel-batch-delete",
    "book-info": "view-book-info|open-cover",
    "full-title": "read-full-title",
    "image-source": "choose-camera|choose-gallery|choose-ocr",
    "image-replace-options": "replace-with-camera|replace-with-file",
    "replace-image-confirmation": "confirm-replace-image|cancel-replace-image",
    "add-memorable-page": "capture-memorable-page|run-ocr|save-memorable-page",
    "existing-image": "view-image|replace-image|delete-image",
    "extracted-text": "review-extracted-text|copy-extracted-text|save-extracted-text",
    "full-text-view": "read-full-text|copy-full-text",
    "page-update": "save-page-update|mark-not-read|cancel-page-update",
    "reading-timer": "start-reading-session|pause-reading-session|finish-reading-session",
    "today-goal": "view-today-goal|open-goal-settings",
    "daily-target": "edit-daily-target|save-daily-target",
    "daily-target-confirm": "confirm-daily-target|cancel-daily-target",
    "update-target-date": "edit-target-date|save-target-date",
    "edit-planned-book": "edit-planned-book|save-planned-book",
    "book-completion": "acknowledge-completion|open-review-prompt",
    "book-review-prompt": "write-review|dismiss-review-prompt",
    "review-exit-confirmation": "discard-review-changes|keep-review-changes",
    "review-save-complete": "acknowledge-review-save|open-review-book",
    "password-change": "change-password|cancel-password-change",
    "delete-account-confirmation": "confirm-account-deletion|cancel-account-deletion",
    "notification-time-picker": "set-daily-reminder-time|set-goal-alarm-time",
    "ocr-limit": "show-ocr-quota|continue-without-ocr",
    "pro-features": "explain-web-billing-disabled",
    "floating-timer": "open-running-timer|stop-running-timer",
    "schedule-change": "adjust-daily-target|preview-reading-schedule|confirm-schedule-change",
    "calendar-month-picker": "choose-calendar-month|confirm-calendar-month|cancel-calendar-month",
    "clear-ai-memory-confirmation": "cancel-ai-memory-clear|confirm-ai-memory-clear",
    "mind-map-leaf-detail": "open-mind-map-leaf|close-mind-map-leaf",
    "mind-map-cluster-detail": "open-mind-map-cluster|close-mind-map-cluster",
    "review-link-editor": "edit-review-link|save-review-link|delete-review-link|cancel-review-link",
    "context-menu": "choose-context-action|dismiss-context-menu",
    "search-overlay": "search-with-keyboard|dismiss-search-overlay",
    "full-screen-image": "view-full-screen-image|close-full-screen-image",
  },
  native_only_capabilities: {
    "ios-home-widget": "open-widget-book",
    "siri-app-shortcuts": "continue-reading-shortcut|scan-page-shortcut|add-book-shortcut|record-shortcut-boundary",
    "native-push": "request-web-push|manage-notification-categories|open-notification-deep-link",
    "camera-and-ocr": "capture-or-upload|extract-ocr|manual-text-fallback",
    "share-sheet": "share-book|download-share-card",
    subscriptions: "show-billing-disabled",
    "offline-boundary": "show-network-status|preserve-proven-draft|retry-online-write",
    "deep-links": "open-book-deep-link|open-record-deep-link|recover-auth-deep-link",
  },
};
const requiredDeepLinkIds = [
  "book-search-deep-link",
  "book-detail-deep-link",
  "book-record-deep-link",
  "book-scan-deep-link",
  "auth-next-return",
];
const requiredNativeActionAssertions = {
  routes: {
    "book-detail": ["resume-reading", "start-planned-reading"],
  },
  native_only_capabilities: {
    "siri-app-shortcuts": ["continue-reading-shortcut", "scan-page-shortcut", "add-book-shortcut"],
  },
};
const nativeCapabilityRequiredSources = {
  "siri-app-shortcuts": [
    "app/ios/Runner/BookgolasShortcuts.swift",
    "app/ios/Runner/AppDelegate.swift",
    "app/ios/Runner/Info.plist",
  ],
};
const negativeFixtureNames = [
  "missing-disposition",
  "duplicate-canonical-url",
  "missing-error-state",
  "missing-required-state",
  "complete-without-evidence",
  "complete-with-invalid-evidence",
  "complete-with-fabricated-evidence",
  "invalid-native-boundary",
  "missing-deep-link",
  "invalid-deep-link-target",
  "invalid-deep-link-source",
  "missing-native-overlay",
  "missing-native-action",
  "invalid-billing-route",
  "invalid-billing-overlay",
  "invalid-billing-claim",
  "complete-with-aliased-evidence",
  "unsafe-source-reference",
  "invalid-native-source",
  "invalid-action-assertion",
  "unsafe-evidence-source",
  "missing-required-native-surface",
  "missing-required-native-action",
  "invalid-web-target",
  "invalid-source-inventory",
  "invalid-canonical-path",
  "complete-with-cross-role-alias",
  "missing-action-assertion",
];
const negativeFixtureExpectations = {
  "missing-disposition": "has invalid web disposition",
  "duplicate-canonical-url": "duplicate canonical_url",
  "missing-error-state": "state profile default is missing error",
  "missing-required-state": "state_contract.required must include",
  "complete-without-evidence": "cannot be complete without evidence",
  "complete-with-invalid-evidence": "evidence 1 must be an object",
  "complete-with-fabricated-evidence": "source does not exist in the repository",
  "invalid-native-boundary": "subscriptions must use disposition disabled",
  "missing-deep-link": "missing required deep link",
  "invalid-deep-link-target": "must map to",
  "invalid-deep-link-source": "missing required deep link",
  "missing-native-overlay": "required overlays surface is missing from ledger",
  "missing-native-action": "is missing native action google-sign-in",
  "invalid-billing-route": "subscription must use disposition disabled",
  "invalid-billing-overlay": "pro-features must use disposition disabled",
  "invalid-billing-claim": "contains a billing claim",
  "complete-with-aliased-evidence": "evidence sources and artifacts must be independent",
  "unsafe-source-reference": "references a missing or unsafe path",
  "invalid-native-source": "references a missing or unsafe path",
  "invalid-action-assertion": "is not present",
  "unsafe-evidence-source": "source does not exist in the repository",
  "missing-required-native-surface": "required routes surface is missing from ledger",
  "missing-required-native-action": "required native action is missing from ledger",
  "invalid-web-target": "Web target must not be an external URL",
  "invalid-source-inventory": "source_inventory paths references a missing or unsafe path",
  "invalid-canonical-path": "canonical_url must be a locale-relative path",
  "complete-with-cross-role-alias": "evidence sources and artifacts must be independent",
  "missing-action-assertion": "required native action assertion is missing",
};
const disabledConsumerWebRules = {
  subscription: { disposition: "disabled", status: "disabled" },
  "pro-features": { disposition: "disabled", status: "disabled" },
};
const billingClaimPattern = /\b(revenuecat|billing|purchase|restore|upgrade|customer center|paywall|pro feature|pro-features)\b/i;
const subscriptionWebPathPattern = /\bsubscriptions?\b/i;

const fixtureIndex = process.argv.indexOf("--fixture");
const fixtureName = fixtureIndex >= 0 ? process.argv[fixtureIndex + 1] : null;

if (fixtureName === "missing-disposition") {
  ledger.routes[0].web.disposition = "";
}

if (fixtureName === "duplicate-canonical-url") {
  ledger.routes[1].web.canonical_url = ledger.routes[0].web.canonical_url;
}

if (fixtureName === "missing-error-state") {
  ledger.state_contract.profiles.default.error = "";
}

if (fixtureName === "missing-required-state") {
  ledger.state_contract.required = expectedStates.filter((state) => state !== "error");
}

if (fixtureName === "complete-without-evidence") {
  ledger.routes[0].web.status = "complete";
  delete ledger.routes[0].evidence;
}

if (fixtureName === "complete-with-invalid-evidence") {
  ledger.routes[0].web.status = "complete";
  ledger.routes[0].evidence = ["invented evidence"];
}

if (fixtureName === "complete-with-fabricated-evidence") {
  ledger.routes[0].web.status = "complete";
  ledger.routes[0].evidence = [
    {
      kind: "data",
      source: "/tmp/invented-evidence",
      artifact: "/tmp/invented-evidence",
      observation: "Invented data observation",
    },
    {
      kind: "browser",
      source: "/tmp/invented-evidence",
      artifact: "/tmp/invented-evidence",
      observation: "Invented browser observation",
    },
  ];
}

if (fixtureName === "invalid-native-boundary") {
  ledger.native_only_capabilities.find((entry) => entry.id === "subscriptions").web = {
    ...ledger.native_only_capabilities.find((entry) => entry.id === "subscriptions").web,
    disposition: "browser-equivalent",
    status: "planned",
  };
}

if (fixtureName === "missing-deep-link") {
  ledger.deep_links.shift();
}

if (fixtureName === "invalid-deep-link-target") {
  ledger.deep_links.find((link) => link.source === "bookgolas://book/detail/{bookId}").canonical_web_url = "/{locale}/wrong/{bookId}";
}

if (fixtureName === "invalid-deep-link-source") {
  ledger.deep_links[0].source = "bookgolas://unknown/action";
}

if (fixtureName === "missing-native-overlay") {
  ledger.overlays = ledger.overlays.filter((entry) => entry.id !== "schedule-change");
}

if (fixtureName === "missing-native-action") {
  ledger.routes[0].actions = ledger.routes[0].actions.filter((action) => action.id !== "google-sign-in");
}

if (fixtureName === "invalid-billing-route") {
  ledger.routes.find((entry) => entry.id === "subscription").web = {
    ...ledger.routes.find((entry) => entry.id === "subscription").web,
    target: ["web/src/app/[locale]/subscription/page.tsx"],
    disposition: "route",
    status: "planned",
  };
}

if (fixtureName === "invalid-billing-overlay") {
  ledger.overlays.find((entry) => entry.id === "pro-features").web = {
    ...ledger.overlays.find((entry) => entry.id === "pro-features").web,
    target: ["web/src/components/consumer/pro-features.tsx"],
    disposition: "component",
    status: "planned",
  };
}

if (fixtureName === "invalid-billing-claim") {
  ledger.routes[0].notes = "RevenueCat purchase and upgrade surface";
  ledger.routes[0].web = {
    ...ledger.routes[0].web,
    target: ["web/src/app/[locale]/billing/page.tsx"],
    disposition: "route",
    status: "planned",
  };
}

if (fixtureName === "complete-with-aliased-evidence") {
  ledger.routes[0].web.status = "complete";
  ledger.routes[0].evidence = [
    {
      kind: "data",
      source: "web/docs/consumer-parity-matrix.md",
      artifact: "web/docs/consumer-parity-ledger.json",
      source_contains: "Canonical consumer routes",
      artifact_contains: "\"routes\": [",
      observation: "Data contract observation",
      commit: currentCommit,
    },
    {
      kind: "browser",
      source: "web/docs/./consumer-parity-matrix.md",
      artifact: "web/docs/native-consumer-surface-inventory.json",
      source_contains: "Validation",
      artifact_contains: "native_action_assertions",
      observation: "Browser contract observation",
      commit: currentCommit,
    },
  ];
}

if (fixtureName === "unsafe-source-reference") {
  ledger.routes[0].native_source.push("web/../../../etc/passwd");
}

if (fixtureName === "invalid-native-source") {
  ledger.routes[0].native_source.push("fabricated native source");
}

if (fixtureName === "invalid-action-assertion") {
  nativeInventory.native_action_assertions.native_only_capabilities["siri-app-shortcuts"]["continue-reading-shortcut"][0].contains = "missing shortcut implementation";
}

if (fixtureName === "unsafe-evidence-source") {
  ledger.routes[0].web.status = "complete";
  ledger.routes[0].evidence = [
    {
      kind: "data",
      source: "web/../../../etc/passwd",
      artifact: "web/docs/consumer-parity-ledger.json",
      source_contains: "routes",
      artifact_contains: "Canonical consumer routes",
      observation: "Data contract observation",
      commit: currentCommit,
    },
    {
      kind: "browser",
      source: "web/docs/consumer-parity-matrix.md",
      artifact: "web/docs/native-consumer-surface-inventory.json",
      source_contains: "Validation",
      artifact_contains: "native_action_assertions",
      observation: "Browser contract observation",
      commit: currentCommit,
    },
  ];
}

if (fixtureName === "missing-required-native-surface") {
  ledger.routes = ledger.routes.filter((entry) => entry.id !== "auth-login");
  delete nativeInventory.routes["auth-login"];
}

if (fixtureName === "missing-required-native-action") {
  ledger.routes.find((entry) => entry.id === "reading-stats").actions = ledger.routes
    .find((entry) => entry.id === "reading-stats")
    .actions.filter((action) => action.id !== "stats-share");
  nativeInventory.routes["reading-stats"] = nativeInventory.routes["reading-stats"].filter(
    (actionId) => actionId !== "stats-share",
  );
}

if (fixtureName === "invalid-web-target") {
  ledger.routes[0].web.target = ["https://evil.example/claimed-parity"];
}

if (fixtureName === "invalid-source-inventory") {
  ledger.source_inventory.push("https://evil.example/native-audit");
}

if (fixtureName === "invalid-canonical-path") {
  ledger.routes[0].web.canonical_url = "/{locale}/%2e%2e/%2e%2e/evil";
}

if (fixtureName === "complete-with-cross-role-alias") {
  ledger.routes[0].web.status = "complete";
  ledger.routes[0].evidence = [
    {
      kind: "data",
      source: "web/docs/consumer-parity-ledger.json",
      artifact: "web/docs/consumer-parity-matrix.md",
      source_contains: "routes",
      artifact_contains: "Canonical consumer routes",
      observation: "Data contract observation",
      commit: currentCommit,
    },
    {
      kind: "browser",
      source: "web/docs/consumer-parity-matrix.md",
      artifact: "web/docs/native-consumer-surface-inventory.json",
      source_contains: "Validation",
      artifact_contains: "native_action_assertions",
      observation: "Browser contract observation",
      commit: currentCommit,
    },
  ];
}

if (fixtureName === "missing-action-assertion") {
  delete nativeInventory.native_action_assertions.routes["book-detail"]["resume-reading"];
}

function fail(message) {
  failures.push(message);
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function isNonEmptyArray(value) {
  return Array.isArray(value) && value.length > 0;
}

function hasSameValues(left, right) {
  return Array.isArray(left) && left.length === right.length && right.every((value) => left.includes(value));
}

function isRepositoryReference(value) {
  return typeof value === "string" && /^(app|web|docs|supabase|\.github|\.byungskerlab|\.omo)\//.test(value);
}

function isCanonicalLocalePath(value) {
  if (typeof value !== "string" || !/^\/\{locale\}(?:\/|$)/.test(value) || value.includes("://") || value.includes("\\")) {
    return false;
  }
  try {
    const decodedPath = decodeURIComponent(value.split("?")[0]);
    const segments = decodedPath.split("/").slice(2);
    return segments.every((segment) => segment.length > 0 && segment !== "." && segment !== "..");
  } catch {
    return false;
  }
}

function isSafeRepositoryReference(value) {
  if (!isRepositoryReference(value) || path.isAbsolute(value) || value.split(/[\\/]/).includes("..")) {
    return null;
  }
  const candidate = path.resolve(repositoryRoot, value);
  const relativeCandidate = path.relative(repositoryRoot, candidate);
  return !(relativeCandidate.startsWith("..") || path.isAbsolute(relativeCandidate));
}

function resolveSafeRepositoryPath(value) {
  if (!isSafeRepositoryReference(value)) return null;
  const candidate = path.resolve(repositoryRoot, value);
  if (!fs.existsSync(candidate)) return null;
  try {
    const realRoot = fs.realpathSync(repositoryRoot);
    const realCandidate = fs.realpathSync(candidate);
    const relativeRealCandidate = path.relative(realRoot, realCandidate);
    if (relativeRealCandidate.startsWith("..") || path.isAbsolute(relativeRealCandidate)) {
      return null;
    }
    return realCandidate;
  } catch {
    return null;
  }
}

function checkExistingReferences(entry, fieldName, values) {
  for (const value of values ?? []) {
    if (!isNonEmptyString(value) || !resolveSafeRepositoryPath(value)) {
      fail(entry.id + " " + fieldName + " references a missing or unsafe path " + value);
    }
  }
}

function checkStateProfiles() {
  if (ledger.schema_version !== 1) {
    fail("schema_version must be 1");
  }

  if (JSON.stringify(ledger.locales) !== JSON.stringify(["ko", "en"])) {
    fail("locales must be exactly ko and en");
  }

  if (ledger.release?.delivery_unit !== "web") {
    fail("release delivery_unit must be web");
  }

  if (ledger.release?.target_version !== "1.1.0") {
    fail("release target_version must be 1.1.0");
  }

  if (ledger.release?.delivery_profile !== "web-release-train") {
    fail("release delivery_profile must be web-release-train");
  }

  if (ledger.release?.parity_policy !== "online-core") {
    fail("release parity_policy must be online-core");
  }

  for (const [dependency, expected] of Object.entries(requiredDeliveryDependencies)) {
    if (ledger.release?.delivery_dependencies?.[dependency] !== expected) {
      fail("release delivery_dependencies." + dependency + " must be " + expected);
    }
  }

  if (!isNonEmptyString(ledger.release?.reference_implementation)) {
    fail("reference_implementation is required");
  }

  if (!/^[0-9a-f]{40}$/.test(currentCommit)) {
    fail("current Git commit is unavailable for evidence binding");
  }

  if (!hasSameValues(ledger.state_contract?.required, expectedStates)) {
    fail("state_contract.required must include exactly " + expectedStates.join(", "));
  }

  for (const profileName of expectedStateProfiles) {
    if (!ledger.state_contract?.profiles?.[profileName]) {
      fail("missing required state profile " + profileName);
    }
  }

  for (const [profileName, profile] of Object.entries(ledger.state_contract?.profiles ?? {})) {
    for (const state of requiredStates) {
      if (!isNonEmptyString(profile[state])) {
        fail("state profile " + profileName + " is missing " + state);
      }
    }
  }
}

function checkAction(entry, action, index) {
  if (!isNonEmptyString(action?.id)) {
    fail(entry.id + " action " + (index + 1) + " is missing id");
  }

  if (!isNonEmptyString(action?.label)) {
    fail(entry.id + " action " + (action?.id ?? index + 1) + " is missing label");
  }

  if (!isNonEmptyString(action?.owner)) {
    fail(entry.id + " action " + (action?.id ?? index + 1) + " is missing owner");
  }

  if (!allowedStatuses.has(action?.status)) {
    fail(entry.id + " action " + (action?.id ?? index + 1) + " has invalid status");
  }
}

function checkWebTargets(entry, web) {
  if (web.target === undefined) return;
  if (!Array.isArray(web.target)) {
    fail(entry.id + " Web target must be an array");
    return;
  }
  for (const target of web.target) {
    if (!isNonEmptyString(target)) {
      fail(entry.id + " Web target must contain non-empty strings");
      continue;
    }
    if (/^[a-z][a-z0-9+.-]*:\/\//i.test(target) || target.startsWith("//")) {
      fail(entry.id + " Web target must not be an external URL");
    }
    if (isRepositoryReference(target) && !isSafeRepositoryReference(target)) {
      fail(entry.id + " Web target references a missing or unsafe path " + target);
    }
  }
}

function checkEntry(entry, groupName) {
  if (!isNonEmptyString(entry?.id)) {
    fail(groupName + " entry is missing id");
  }

  if (!isNonEmptyArray(entry?.native_source)) {
    fail((entry?.id ?? groupName) + " is missing native_source");
  } else {
    checkExistingReferences(entry, "native_source", entry.native_source);
  }

  if (!isNonEmptyString(entry?.native_entry) && groupName === "routes") {
    fail((entry?.id ?? groupName) + " is missing native_entry");
  }

  if (!isNonEmptyString(entry?.evidence_owner)) {
    fail((entry?.id ?? groupName) + " is missing evidence_owner");
  }

  if (!isNonEmptyString(entry?.state_profile)) {
    fail((entry?.id ?? groupName) + " is missing state_profile");
  } else if (!ledger.state_contract?.profiles?.[entry.state_profile]) {
    fail(entry.id + " references unknown state profile " + entry.state_profile);
  }

  if (!isNonEmptyArray(entry?.actions)) {
    fail((entry?.id ?? groupName) + " must have at least one action");
  } else {
    const actionIds = new Set();
    entry.actions.forEach((action, index) => {
      checkAction(entry, action, index);
      if (actionIds.has(action?.id)) {
        fail(entry.id + " has duplicate action id " + action.id);
      }
      actionIds.add(action?.id);
    });
  }

  const web = entry?.web;
  if (!web || typeof web !== "object") {
    fail((entry?.id ?? groupName) + " is missing web disposition");
    return;
  }

  if (!allowedWebDispositions.has(web.disposition)) {
    fail((entry?.id ?? groupName) + " has invalid web disposition");
  }

  if (!allowedStatuses.has(web.status)) {
    fail((entry?.id ?? groupName) + " has invalid web status");
  }

  checkWebTargets(entry, web);

  const disabledRule = disabledConsumerWebRules[entry.id];
  if (disabledRule) {
    if (web.disposition !== disabledRule.disposition) {
      fail(entry.id + " must use disposition " + disabledRule.disposition);
    }
    if (web.status !== disabledRule.status) {
      fail(entry.id + " must use status " + disabledRule.status);
    }
    if (isNonEmptyArray(web.target)) {
      fail(entry.id + " must not define a Web target");
    }
  }

  const webBillingMaterial = JSON.stringify(web);
  if (billingClaimPattern.test(webBillingMaterial) || subscriptionWebPathPattern.test(JSON.stringify(web))) {
    if (web.disposition !== "disabled" || web.status !== "disabled" || isNonEmptyArray(web.target)) {
      fail(entry.id + " contains a billing claim and must remain disabled on Web");
    }
  }

  if (!isNonEmptyArray(web.target) && web.disposition !== "disabled" && web.disposition !== "explicit-unavailability") {
    fail(entry.id + " is missing a Web target");
  }

  if (!isNonEmptyArray(web.current) && web.status === "partial") {
    fail(entry.id + " is partial but has no current Web evidence");
  } else {
    checkExistingReferences(entry, "web.current", web.current);
  }

  if (web.status === "complete") {
    if (!isNonEmptyArray(entry.evidence)) {
      fail(entry.id + " cannot be complete without evidence");
    } else {
      const evidenceKinds = new Set();
      const evidenceReferences = new Set();
      entry.evidence.forEach((evidence, index) => {
        if (!evidence || typeof evidence !== "object" || Array.isArray(evidence)) {
          fail(entry.id + " evidence " + (index + 1) + " must be an object");
          return;
        }
        let sourcePath = null;
        if (!isNonEmptyString(evidence.source)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing source");
        } else {
          sourcePath = resolveSafeRepositoryPath(evidence.source);
          if (!sourcePath) {
            fail(entry.id + " evidence " + (index + 1) + " source does not exist in the repository");
          } else if (evidenceReferences.has(sourcePath)) {
            fail(entry.id + " evidence sources and artifacts must be independent");
          } else {
            evidenceReferences.add(sourcePath);
          }
        }
        if (!isNonEmptyString(evidence.source_contains)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing source_contains");
        } else if (sourcePath && !fs.readFileSync(sourcePath, "utf8").includes(evidence.source_contains)) {
          fail(entry.id + " evidence " + (index + 1) + " source_contains is not present");
        }
        if (!allowedEvidenceKinds.has(evidence.kind)) {
          fail(entry.id + " evidence " + (index + 1) + " has invalid kind");
        } else {
          evidenceKinds.add(evidence.kind);
        }
        if (!isNonEmptyString(evidence.observation)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing observation");
        }
        if (evidence.commit !== currentCommit) {
          fail(entry.id + " evidence " + (index + 1) + " is not bound to the current commit");
        }
        if (!isNonEmptyString(evidence.artifact)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing artifact");
        } else {
          const artifactPath = resolveSafeRepositoryPath(evidence.artifact);
          if (!artifactPath) {
            fail(entry.id + " evidence " + (index + 1) + " artifact is missing or unsafe");
          }
          if (artifactPath && evidenceReferences.has(artifactPath)) {
            fail(entry.id + " evidence sources and artifacts must be independent");
          } else if (artifactPath) {
            evidenceReferences.add(artifactPath);
          }
          if (!isNonEmptyString(evidence.artifact_contains)) {
            fail(entry.id + " evidence " + (index + 1) + " is missing artifact_contains");
          } else if (artifactPath && !fs.readFileSync(artifactPath, "utf8").includes(evidence.artifact_contains)) {
            fail(entry.id + " evidence " + (index + 1) + " artifact_contains is not present");
          }
        }
      });
      for (const kind of allowedEvidenceKinds) {
        if (!evidenceKinds.has(kind)) {
          fail(entry.id + " complete evidence must include " + kind + " evidence");
        }
      }
    }
  }
}

function checkRoutes() {
  const canonicalUrls = new Set();
  for (const route of ledger.routes ?? []) {
    checkEntry(route, "routes");
    const canonicalUrl = route?.web?.canonical_url;
    if (!isNonEmptyString(canonicalUrl)) {
      fail((route?.id ?? "route") + " is missing canonical_url");
    } else {
      if (!isCanonicalLocalePath(canonicalUrl)) {
        fail(route.id + " canonical_url must be a locale-relative path");
      }
      if (canonicalUrls.has(canonicalUrl)) {
        fail("duplicate canonical_url " + canonicalUrl);
      }
      canonicalUrls.add(canonicalUrl);
    }
  }
}

function checkDeepLinks() {
  if (!isNonEmptyArray(ledger.deep_links)) {
    fail("deep_links must not be empty");
    return;
  }

  const sources = new Set();
  const ids = new Set();
  for (const link of ledger.deep_links) {
    if (!isNonEmptyString(link?.id)) {
      fail("deep link is missing id");
    } else if (ids.has(link.id)) {
      fail("duplicate deep link id " + link.id);
    } else {
      ids.add(link.id);
    }
    if (!isNonEmptyString(link?.source)) {
      fail((link?.id ?? "deep link") + " is missing source");
    } else if (sources.has(link.source)) {
      fail("duplicate deep link source " + link.source);
    } else {
      sources.add(link.source);
    }
    if (!allowedDeepLinkKinds.has(link?.source_kind)) {
      fail((link?.id ?? "deep link") + " has invalid source_kind");
    }
    if (!isNonEmptyArray(link?.native_source)) {
      fail((link?.id ?? "deep link") + " is missing native_source");
    } else {
      checkExistingReferences(link, "native_source", link.native_source);
    }
    if (!isCanonicalLocalePath(link?.canonical_web_url)) {
      fail((link?.id ?? "deep link") + " canonical_web_url must be a locale-relative path");
    }
    if (link?.disposition !== "browser-equivalent") {
      fail((link?.id ?? "deep link") + " must be browser-equivalent");
    }
    if (!allowedStatuses.has(link?.status)) {
      fail((link?.id ?? "deep link") + " has invalid status");
    }
    if (!isNonEmptyString(link?.owner)) {
      fail((link?.id ?? "deep link") + " is missing owner");
    }
  }

  for (const [source, canonicalUrl] of requiredDeepLinkMappings) {
    if (!sources.has(source)) {
      fail("missing required deep link " + source);
    }
    const link = ledger.deep_links.find((candidate) => candidate.source === source);
    if (link && link.canonical_web_url !== canonicalUrl) {
      fail(source + " must map to " + canonicalUrl);
    }
  }
  for (const source of sources) {
    if (!requiredDeepLinkMappings.has(source)) {
      fail("unallowlisted deep link " + source);
    }
  }
}

function checkNativeInventory() {
  if (nativeInventory.schema_version !== 1 || !isNonEmptyString(nativeInventory.source)) {
    fail("native consumer surface inventory metadata is invalid");
  }

  const groups = [
    ["routes", ledger.routes],
    ["overlays", ledger.overlays],
    ["native_only_capabilities", ledger.native_only_capabilities],
  ];

  for (const [groupName, ledgerEntries] of groups) {
    const expectedEntries = nativeInventory[groupName];
    if (!expectedEntries || typeof expectedEntries !== "object" || Array.isArray(expectedEntries)) {
      fail("native inventory is missing group " + groupName);
      continue;
    }

    const ledgerById = new Map((ledgerEntries ?? []).map((entry) => [entry.id, entry]));
    const requiredIds = requiredNativeSurfaceIds[groupName] ?? [];
    for (const requiredId of requiredIds) {
      if (!ledgerById.has(requiredId)) {
        fail("required " + groupName + " surface is missing from ledger: " + requiredId);
      }
      if (!Object.prototype.hasOwnProperty.call(expectedEntries, requiredId)) {
        fail("required " + groupName + " surface is missing from native inventory: " + requiredId);
      }
    }
    const expectedIds = Object.keys(expectedEntries);
    for (const expectedId of expectedIds) {
      const entry = ledgerById.get(expectedId);
      if (!entry) {
        fail(groupName + " is missing native surface " + expectedId);
        continue;
      }
      const expectedActions = expectedEntries[expectedId];
      const actualActions = (entry.actions ?? []).map((action) => action.id);
      if (!isNonEmptyArray(expectedActions)) {
        fail("native inventory " + groupName + "." + expectedId + " must list actions");
        continue;
      }
      for (const actionId of expectedActions) {
        if (!actualActions.includes(actionId)) {
          fail(groupName + " " + expectedId + " is missing native action " + actionId);
        }
      }
      for (const actionId of actualActions) {
        if (!expectedActions.includes(actionId)) {
          fail(groupName + " " + expectedId + " has untracked action " + actionId);
        }
      }
    }
    for (const entry of ledgerEntries ?? []) {
      if (!Object.prototype.hasOwnProperty.call(expectedEntries, entry.id)) {
        fail(groupName + " has untracked native surface " + entry.id);
      }
    }

    for (const [requiredId, actionList] of Object.entries(requiredNativeActionIds[groupName] ?? {})) {
      const entry = ledgerById.get(requiredId);
      const inventoryActions = expectedEntries[requiredId];
      for (const actionId of actionList.split("|")) {
        if (!entry || !(entry.actions ?? []).some((action) => action.id === actionId)) {
          fail("required native action is missing from ledger: " + groupName + "." + requiredId + "." + actionId);
        }
        if (!Array.isArray(inventoryActions) || !inventoryActions.includes(actionId)) {
          fail("required native action is missing from native inventory: " + groupName + "." + requiredId + "." + actionId);
        }
      }
    }
  }

  const expectedDeepLinks = nativeInventory.deep_links;
  if (!isNonEmptyArray(expectedDeepLinks)) {
    fail("native inventory deep_links must not be empty");
  } else {
    const actualDeepLinks = new Map((ledger.deep_links ?? []).map((link) => [link.id, link.source]));
    const expectedDeepLinkIds = new Map(expectedDeepLinks.map((link) => [link.id, link.source]));
    for (const requiredId of requiredDeepLinkIds) {
      if (!actualDeepLinks.has(requiredId)) {
        fail("required deep link is missing from ledger: " + requiredId);
      }
      if (!expectedDeepLinkIds.has(requiredId)) {
        fail("required deep link is missing from native inventory: " + requiredId);
      }
    }
    for (const [id, source] of expectedDeepLinkIds) {
      if (actualDeepLinks.get(id) !== source) {
        fail("deep link inventory mismatch for " + id);
      }
    }
    for (const id of actualDeepLinks.keys()) {
      if (!expectedDeepLinkIds.has(id)) {
        fail("deep_links has untracked native source " + id);
      }
    }
  }
}

function checkSourceInventory() {
  if (!isNonEmptyArray(ledger.source_inventory)) {
    fail("source_inventory must not be empty");
    return;
  }
  checkExistingReferences({ id: "source_inventory" }, "paths", ledger.source_inventory);
}

function checkNativeOnlyCapabilities() {
  const capabilityIds = new Set((ledger.native_only_capabilities ?? []).map((entry) => entry.id));

  for (const capabilityId of Object.keys(nativeCapabilityRules)) {
    if (!capabilityIds.has(capabilityId)) {
      fail("missing required capability " + capabilityId);
    }
  }

  for (const capability of ledger.native_only_capabilities ?? []) {
    checkEntry(capability, "native_only_capabilities");
    if (!isNonEmptyString(capability.native_presence)) {
      fail(capability.id + " is missing native_presence");
    }
    for (const source of nativeCapabilityRequiredSources[capability.id] ?? []) {
      if (!capability.native_source.includes(source)) {
        fail(capability.id + " is missing native source " + source);
      }
    }
    const expectedRule = nativeCapabilityRules[capability.id];
    if (!expectedRule) {
      fail(capability.id + " is not in the native capability boundary contract");
      continue;
    }
    if (capability?.web?.disposition !== expectedRule.disposition) {
      fail(capability.id + " must use disposition " + expectedRule.disposition);
    }
    if (capability?.web?.status !== expectedRule.status) {
      fail(capability.id + " must use status " + expectedRule.status);
    }
  }
}

function checkNativeActionAssertions() {
  const assertionGroups = nativeInventory.native_action_assertions;
  if (!assertionGroups || typeof assertionGroups !== "object" || Array.isArray(assertionGroups)) {
    fail("native inventory native_action_assertions are missing");
    return;
  }

  for (const [groupName, entryRequirements] of Object.entries(requiredNativeActionAssertions)) {
    for (const [entryId, requiredActions] of Object.entries(entryRequirements)) {
      const assertions = assertionGroups[groupName]?.[entryId];
      for (const actionId of requiredActions) {
        if (!assertions || !Object.prototype.hasOwnProperty.call(assertions, actionId)) {
          fail("required native action assertion is missing: " + groupName + "." + entryId + "." + actionId);
        }
      }
    }
  }

  for (const [groupName, entryAssertions] of Object.entries(assertionGroups)) {
    const ledgerEntries = ledger[groupName];
    if (!Array.isArray(ledgerEntries)) {
      fail("native action assertions reference unknown group " + groupName);
      continue;
    }
    for (const [entryId, actionAssertions] of Object.entries(entryAssertions ?? {})) {
      const entry = ledgerEntries.find((candidate) => candidate.id === entryId);
      if (!entry) {
        fail("native action assertions reference missing surface " + groupName + "." + entryId);
        continue;
      }
      const actionIds = new Set((entry.actions ?? []).map((action) => action.id));
      for (const [actionId, assertions] of Object.entries(actionAssertions ?? {})) {
        if (!actionIds.has(actionId)) {
          fail("native action assertions reference missing action " + groupName + "." + entryId + "." + actionId);
        }
        if (!isNonEmptyArray(assertions)) {
          fail("native action assertions for " + groupName + "." + entryId + "." + actionId + " must not be empty");
          continue;
        }
        for (const assertion of assertions) {
          if (!isNonEmptyString(assertion?.source) || !isNonEmptyString(assertion?.contains)) {
            fail("native action assertion for " + groupName + "." + entryId + "." + actionId + " is incomplete");
            continue;
          }
          const sourcePath = resolveSafeRepositoryPath(assertion.source);
          if (!sourcePath) {
            fail("native action assertion references missing or unsafe path " + assertion.source);
            continue;
          }
          const sourceText = fs.readFileSync(sourcePath, "utf8");
          if (!sourceText.includes(assertion.contains)) {
            fail(
              "native action assertion " +
                groupName +
                "." +
                entryId +
                "." +
                actionId +
                " is not present in " +
                assertion.source,
            );
          }
        }
      }
    }
  }
}

function checkDeepLinkAssertions() {
  const assertionsById = nativeInventory.deep_link_assertions;
  if (!assertionsById || typeof assertionsById !== "object" || Array.isArray(assertionsById)) {
    fail("native inventory deep_link_assertions are missing");
    return;
  }

  const ledgerDeepLinks = new Map((ledger.deep_links ?? []).map((link) => [link.id, link]));
  for (const requiredId of requiredDeepLinkIds) {
    if (!Object.prototype.hasOwnProperty.call(assertionsById, requiredId)) {
      fail("required deep link assertion is missing from native inventory: " + requiredId);
    }
  }

  for (const [deepLinkId, assertions] of Object.entries(assertionsById)) {
    const link = ledgerDeepLinks.get(deepLinkId);
    if (!link) {
      fail("deep link assertions reference missing link " + deepLinkId);
      continue;
    }
    if (!isNonEmptyArray(assertions)) {
      fail("deep link assertions for " + deepLinkId + " must not be empty");
      continue;
    }
    for (const assertion of assertions) {
      if (!isNonEmptyString(assertion?.source) || !isNonEmptyString(assertion?.contains)) {
        fail("deep link assertion for " + deepLinkId + " is incomplete");
        continue;
      }
      const sourcePath = resolveSafeRepositoryPath(assertion.source);
      if (!sourcePath) {
        fail("deep link assertion references missing or unsafe path " + assertion.source);
        continue;
      }
      const sourceText = fs.readFileSync(sourcePath, "utf8");
      if (!sourceText.includes(assertion.contains)) {
        fail("deep link assertion " + deepLinkId + " is not present in " + assertion.source);
      }
    }
  }
}

checkStateProfiles();

const allEntries = [
  ...(ledger.routes ?? []),
  ...(ledger.overlays ?? []),
  ...(ledger.native_only_capabilities ?? []),
];
const entryIds = new Set();
for (const entry of allEntries) {
  if (entryIds.has(entry?.id)) {
    fail("duplicate entry id " + entry.id);
  }
  entryIds.add(entry?.id);
}

if (!isNonEmptyArray(ledger.routes)) {
  fail("routes must not be empty");
}

if (!isNonEmptyArray(ledger.overlays)) {
  fail("overlays must not be empty");
}

if (!isNonEmptyArray(ledger.native_only_capabilities)) {
  fail("native_only_capabilities must not be empty");
}

checkRoutes();
checkDeepLinks();
checkSourceInventory();
checkNativeInventory();
checkNativeActionAssertions();
checkDeepLinkAssertions();
for (const overlay of ledger.overlays ?? []) {
  checkEntry(overlay, "overlays");
  if (overlay?.web?.canonical_url !== null) {
    fail(overlay.id + " overlay canonical_url must be null");
  }
}
checkNativeOnlyCapabilities();

if (process.argv.includes("--assert-fixtures")) {
  const unexpectedPasses = [];
  for (const fixture of negativeFixtureNames) {
    try {
      execFileSync(process.execPath, [fileURLToPath(import.meta.url), "--fixture", fixture], {
        cwd: repositoryRoot,
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"],
      });
      unexpectedPasses.push(fixture);
    } catch (error) {
      const output = String(error.stdout ?? "") + String(error.stderr ?? "");
      if (error.status !== 1 || !output.includes(negativeFixtureExpectations[fixture])) {
        unexpectedPasses.push(fixture + " (unexpected exit " + (error.status ?? "signal") + ")");
      }
    }
  }
  for (const fixture of unexpectedPasses) {
    fail("negative fixture unexpectedly passed: " + fixture);
  }
}

if (failures.length > 0) {
  console.error("parity matrix failed with " + failures.length + " error(s)");
  for (const failure of failures) {
    console.error("- " + failure);
  }
  process.exitCode = 1;
} else {
  if (process.argv.includes("--assert-fixtures")) {
    console.log("parity negative fixtures passed: " + negativeFixtureNames.length);
  } else {
    console.log(
      "parity matrix passed: " +
        ledger.routes.length +
        " routes, " +
        ledger.overlays.length +
        " overlays, " +
        ledger.native_only_capabilities.length +
        " capabilities",
    );
  }
}
