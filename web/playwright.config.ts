import { defineConfig } from "@playwright/test";

const configuredBaseURL = process.env.PLAYWRIGHT_BASE_URL ?? "http://127.0.0.1:3000";
const parsedBaseURL = new URL(configuredBaseURL);
const loopbackHosts = new Set(["localhost", "127.0.0.1", "::1", "[::1]"]);
if (
  !["http:", "https:"].includes(parsedBaseURL.protocol) ||
  !loopbackHosts.has(parsedBaseURL.hostname) ||
  parsedBaseURL.username ||
  parsedBaseURL.password
) {
  throw new Error("PLAYWRIGHT_BASE_URL must be a credential-free loopback HTTP(S) URL");
}
if (!parsedBaseURL.port) parsedBaseURL.port = "3000";
const baseURL = parsedBaseURL.toString().replace(/\/$/, "");
const port = parsedBaseURL.port;

export default defineConfig({
  testDir: "./tests/e2e",
  timeout: 30_000,
  use: {
    baseURL,
    trace: "off",
  },
  projects: [
    {
      name: "chromium",
      use: { browserName: "chromium" },
    },
    {
      name: "firefox",
      use: { browserName: "firefox" },
    },
    {
      name: "webkit",
      use: { browserName: "webkit" },
    },
  ],
  webServer: {
    command: `npm run build && npm run start -- --hostname 127.0.0.1 --port ${port}`,
    url: baseURL,
    reuseExistingServer: false,
    timeout: 120_000,
  },
});
