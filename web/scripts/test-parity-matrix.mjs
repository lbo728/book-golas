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
const disabledConsumerWebRules = {
  subscription: { disposition: "disabled", status: "disabled" },
  "pro-features": { disposition: "disabled", status: "disabled" },
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
  return typeof value === "string" && /^(app|web|docs|supabase|\.github|\.byungskerlab)\//.test(value);
}

function checkExistingReferences(entry, fieldName, values) {
  for (const value of values ?? []) {
    if (isRepositoryReference(value) && !fs.existsSync(path.resolve(repositoryRoot, value))) {
      fail(entry.id + " " + fieldName + " references missing path " + value);
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
      const evidenceSources = new Set();
      const evidenceArtifacts = new Set();
      entry.evidence.forEach((evidence, index) => {
        if (!evidence || typeof evidence !== "object" || Array.isArray(evidence)) {
          fail(entry.id + " evidence " + (index + 1) + " must be an object");
          return;
        }
        if (!isNonEmptyString(evidence.source)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing source");
        } else if (evidenceSources.has(evidence.source)) {
          fail(entry.id + " evidence sources must be independent");
        } else {
          evidenceSources.add(evidence.source);
        }
        if (!allowedEvidenceKinds.has(evidence.kind)) {
          fail(entry.id + " evidence " + (index + 1) + " has invalid kind");
        } else {
          evidenceKinds.add(evidence.kind);
        }
        if (!isNonEmptyString(evidence.observation)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing observation");
        }
        if (!isNonEmptyString(evidence.artifact)) {
          fail(entry.id + " evidence " + (index + 1) + " is missing artifact");
        } else {
          const artifactPath = path.resolve(repositoryRoot, evidence.artifact);
          const relativeArtifactPath = path.relative(repositoryRoot, artifactPath);
          if (relativeArtifactPath.startsWith("..") || path.isAbsolute(relativeArtifactPath)) {
            fail(entry.id + " evidence " + (index + 1) + " artifact is outside the repository");
          } else if (!fs.existsSync(artifactPath)) {
            fail(entry.id + " evidence " + (index + 1) + " artifact does not exist");
          }
          if (evidenceArtifacts.has(evidence.artifact)) {
            fail(entry.id + " evidence artifacts must be independent");
          } else {
            evidenceArtifacts.add(evidence.artifact);
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

  for (const [source, canonicalUrl] of requiredDeepLinkMappings) {
    if (!sources.has(source)) {
      fail("missing required deep link " + source);
    }
    const link = ledger.deep_links.find((candidate) => candidate.source === source);
    if (link && link.canonical_web_url !== canonicalUrl) {
      fail(source + " must map to " + canonicalUrl);
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
  }

  const expectedDeepLinks = nativeInventory.deep_links;
  if (!isNonEmptyArray(expectedDeepLinks)) {
    fail("native inventory deep_links must not be empty");
  } else {
    const actualDeepLinks = new Map((ledger.deep_links ?? []).map((link) => [link.id, link.source]));
    const expectedDeepLinkIds = new Map(expectedDeepLinks.map((link) => [link.id, link.source]));
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
    if (
      capability.id === "siri-app-shortcuts" &&
      !capability.native_source.some((source) => source.startsWith("Repository-wide audit for Siri"))
    ) {
      fail("siri-app-shortcuts must retain the repository-wide absence audit");
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
checkNativeInventory();
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
