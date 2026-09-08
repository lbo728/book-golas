import fs from "node:fs";
import path from "node:path";

const webRoot = path.resolve(import.meta.dirname, "..");
const fixtureRoot = path.join(webRoot, "fixtures/supabase");
const manifestPath = path.join(fixtureRoot, "consumer-fixtures.json");
const seedPath = path.join(fixtureRoot, "seed.sql");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const seed = fs.readFileSync(seedPath, "utf8");
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const secretPatterns = [
  /service[_-]?role[_-]?key\s*[:=]\s*[^$\s]+/i,
  /\bsk-[A-Za-z0-9]{20,}\b/,
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/,
];
const failures = [];
/** Collect a fixture contract failure without hiding additional violations. */
const requireCondition = (condition, message) => {
  if (!condition) failures.push(message);
};

requireCondition(manifest.schema_version === 1, "fixture schema_version must be 1");
requireCondition(manifest.fixture_id === "bookgolas-web-414", "fixture id is not pinned");
requireCondition(manifest.users.length === 2, "fixture must contain User A and User B");
requireCondition(manifest.books.length === 2, "fixture must contain two books");
requireCondition(manifest.images.length === 2, "fixture must contain two images");

const userKeys = new Set();
const userIds = new Set();
for (const user of manifest.users) {
  requireCondition(uuid.test(user.id), `invalid user UUID: ${user.key}`);
  requireCondition(!userIds.has(user.id), `duplicate user UUID: ${user.id}`);
  requireCondition(!userKeys.has(user.key), `duplicate user key: ${user.key}`);
  requireCondition(user.email.endsWith("@local.invalid"), `fixture email must use .invalid: ${user.key}`);
  userKeys.add(user.key);
  userIds.add(user.id);
  requireCondition(seed.includes(user.id), `seed is missing user ${user.key}`);
  requireCondition(seed.includes(user.email), `seed is missing email for ${user.key}`);
}

const bookKeys = new Set();
const bookIds = new Set();
for (const book of manifest.books) {
  requireCondition(uuid.test(book.id), `invalid book UUID: ${book.key}`);
  requireCondition(!bookIds.has(book.id), `duplicate book UUID: ${book.id}`);
  requireCondition(userKeys.has(book.user_key), `book owner is missing: ${book.key}`);
  requireCondition(book.current_page <= book.total_pages, `book progress exceeds total: ${book.key}`);
  requireCondition(["planned", "reading", "completed", "will_retry"].includes(book.status), `invalid book status: ${book.key}`);
  bookKeys.add(book.key);
  bookIds.add(book.id);
  requireCondition(seed.includes(book.id), `seed is missing book ${book.key}`);
}

for (const image of manifest.images) {
  requireCondition(uuid.test(image.id), `invalid image UUID: ${image.key}`);
  requireCondition(userKeys.has(image.user_key), `image owner is missing: ${image.key}`);
  requireCondition(bookKeys.has(image.book_key), `image book is missing: ${image.key}`);
  requireCondition(image.mime_type === "image/png", `unexpected image type: ${image.key}`);
  const assetPath = path.resolve(webRoot, "..", image.asset_path);
  const assetRelativePath = path.relative(webRoot, assetPath);
  requireCondition(
    assetRelativePath !== "" &&
      assetRelativePath !== ".." &&
      !assetRelativePath.startsWith(`..${path.sep}`) &&
      !path.isAbsolute(assetRelativePath),
    `image asset escapes Web fixture root: ${image.key}`,
  );
  requireCondition(fs.existsSync(assetPath), `image asset is missing: ${image.asset_path}`);
  requireCondition(seed.includes(image.id), `seed is missing image ${image.key}`);
}

const trackedFixtureFiles = [manifestPath, seedPath];
for (const filePath of trackedFixtureFiles) {
  const contents = fs.readFileSync(filePath, "utf8");
  requireCondition(!secretPatterns.some((pattern) => pattern.test(contents)), `possible secret in ${filePath}`);
}

const negativeSecretFixture = fs.readFileSync(
  path.join(fixtureRoot, "negative/unlabeled-service-role.txt"),
  "utf8",
);
requireCondition(
  secretPatterns.some((pattern) => pattern.test(negativeSecretFixture)),
  "unlabeled JWT negative fixture was not detected",
);

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log("fixture contract passed: 2 isolated users, 2 books, 2 images, local-only credentials and reset seed");
