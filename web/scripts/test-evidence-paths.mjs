import fs from "node:fs";
import path from "node:path";
import { evidenceDirectory } from "./evidence.mjs";

const repositoryRoot = path.resolve(evidenceDirectory, "../../../..");
const evidenceRelativePath = "web/docs/evidence/bookgolas-web-app-parity";
const failures = [];
const requireCondition = (condition, message) => {
  if (!condition) failures.push(message);
};

requireCondition(fs.existsSync(evidenceDirectory), "task evidence directory is missing");
const sumsPath = path.join(evidenceDirectory, "SHA256SUMS");
requireCondition(fs.existsSync(sumsPath), "SHA256SUMS is missing");
requireCondition(fs.existsSync(path.join(evidenceDirectory, "final-verification.md")), "final verification record is missing");

if (fs.existsSync(sumsPath)) {
  const entries = fs.readFileSync(sumsPath, "utf8").trim().split("\n").filter(Boolean);
  requireCondition(entries.length > 0, "SHA256SUMS is empty");
  for (const entry of entries) {
    const [, , relativePath] = entry.match(/^([0-9a-f]{64})  (.+)$/i) ?? [];
    requireCondition(Boolean(relativePath), `malformed checksum entry: ${entry}`);
    if (relativePath) {
      requireCondition(relativePath.startsWith(`${evidenceRelativePath}/`), `evidence path escapes allowed directory: ${relativePath}`);
      requireCondition(!path.isAbsolute(relativePath) && !relativePath.split(path.sep).includes(".."), `evidence path is not repository relative: ${relativePath}`);
      requireCondition(fs.existsSync(path.join(repositoryRoot, relativePath)), `checksum target is missing: ${relativePath}`);
    }
  }
}

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}
console.log("evidence paths passed: repository-relative, scoped, hashed and present");
