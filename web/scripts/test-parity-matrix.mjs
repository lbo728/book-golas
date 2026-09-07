import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const ledgerPath = path.resolve(scriptDirectory, "../docs/consumer-parity-ledger.json");
const ledger = JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
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
const requiredDeepLinkSources = [
  "bookgolas://book/search",
  "bookgolas://book/detail/{bookId}",
  "bookgolas://book/record/{bookId}",
  "bookgolas://book/scan/{bookId}",
  "Auth callback with next",
];
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

  if (!isNonEmptyString(ledger.release?.reference_implementation)) {
    fail("reference_implementation is required");
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

function checkEntry(entry, groupName) {
  if (!isNonEmptyString(entry?.id)) {
    fail(groupName + " entry is missing id");
  }

  if (!isNonEmptyArray(entry?.native_source)) {
    fail((entry?.id ?? groupName) + " is missing native_source");
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

  if (!isNonEmptyArray(web.target) && web.disposition !== "disabled" && web.disposition !== "explicit-unavailability") {
    fail(entry.id + " is missing a Web target");
  }

  if (!isNonEmptyArray(web.current) && web.status === "partial") {
    fail(entry.id + " is partial but has no current Web evidence");
  }

  if (web.status === "complete") {
    if (!isNonEmptyArray(entry.evidence)) {
      fail(entry.id + " cannot be complete without evidence");
    } else {
      const evidenceKinds = new Set();
      entry.evidence.forEach((evidence, index) => {
        if (!evidence || typeof evidence !== "object" || Array.isArray(evidence)) {
          fail(entry.id + " evidence " + (index + 1) + " must be an object");
          return;
        }
        if (!isNonEmptyString(evidence.source)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing source");
        }
        if (!allowedEvidenceKinds.has(evidence.kind)) {
          fail(entry.id + " evidence " + (index + 1) + " has invalid kind");
        } else {
          evidenceKinds.add(evidence.kind);
        }
        if (!isNonEmptyString(evidence.observation)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing observation");
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
      if (!canonicalUrl.includes("{locale}")) {
        fail(route.id + " canonical_url must include {locale}");
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
    }
    if (!isNonEmptyString(link?.canonical_web_url) || !link.canonical_web_url.includes("{locale}")) {
      fail((link?.id ?? "deep link") + " canonical_web_url must include {locale}");
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

  for (const source of requiredDeepLinkSources) {
    if (!sources.has(source)) {
      fail("missing required deep link " + source);
    }
  }
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
for (const overlay of ledger.overlays ?? []) {
  checkEntry(overlay, "overlays");
  if (overlay?.web?.canonical_url !== null) {
    fail(overlay.id + " overlay canonical_url must be null");
  }
}
checkNativeOnlyCapabilities();

if (failures.length > 0) {
  console.error("parity matrix failed with " + failures.length + " error(s)");
  for (const failure of failures) {
    console.error("- " + failure);
  }
  process.exitCode = 1;
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
