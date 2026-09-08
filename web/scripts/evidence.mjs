import path from "node:path";

export const evidenceDirectory = path.resolve(
  import.meta.dirname,
  "../docs/evidence/bookgolas-web-app-parity",
);

export function evidencePath(...parts) {
  const resolved = path.resolve(evidenceDirectory, ...parts);
  if (!resolved.startsWith(`${evidenceDirectory}${path.sep}`)) {
    throw new Error("evidence path escapes the task evidence directory");
  }
  return resolved;
}
