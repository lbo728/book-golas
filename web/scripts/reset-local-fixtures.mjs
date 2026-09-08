import { spawnSync } from "node:child_process";
import path from "node:path";

const repositoryRoot = path.resolve(import.meta.dirname, "../..");
const result = spawnSync(
  "supabase",
  ["db", "reset", "--local", "--sql-paths", "web/fixtures/supabase/seed.sql", "--yes"],
  { cwd: repositoryRoot, stdio: "inherit" },
);

if (result.error) {
  console.error(`local Supabase reset could not start: ${result.error.message}`);
  process.exit(1);
}
if (result.status !== 0) {
  process.exit(result.status ?? 1);
}
console.log("local Supabase fixtures reset from web/fixtures/supabase/seed.sql");
