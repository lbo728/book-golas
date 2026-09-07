import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const ledgerPath = path.resolve(scriptDirectory, "../docs/consumer-parity-ledger.json");
const ledger = JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
const failures = [];
const requiredStates = new Set(ledger.state_contract.required);
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

if (fixtureName === "complete-without-evidence") {
  ledger.routes[0].web.status = "complete";
  delete ledger.routes[0].evidence;
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
  } else if (!ledger.state_contract.profiles[entry.state_profile]) {
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

  if (web.status === "complete" && !isNonEmptyArray(entry.evidence)) {
    fail(entry.id + " cannot be complete without evidence");
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

function checkNativeOnlyCapabilities() {
  const requiredCapabilities = [
    "ios-home-widget",
    "siri-app-shortcuts",
    "native-push",
    "camera-and-ocr",
    "share-sheet",
    "subscriptions",
  ];
  const capabilityIds = new Set((ledger.native_only_capabilities ?? []).map((entry) => entry.id));

  for (const capabilityId of requiredCapabilities) {
    if (!capabilityIds.has(capabilityId)) {
      fail("missing required capability " + capabilityId);
    }
  }

  for (const capability of ledger.native_only_capabilities ?? []) {
    checkEntry(capability, "native_only_capabilities");
    if (!isNonEmptyString(capability.native_presence)) {
      fail(capability.id + " is missing native_presence");
    }
    if (!["browser-equivalent", "disabled", "explicit-unavailability"].includes(capability?.web?.disposition)) {
      fail(capability.id + " must have an explicit native-only Web boundary");
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
