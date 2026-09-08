import crypto from "node:crypto";

function localTestConfig(env = process.env) {
  const url = env.BOOKGOLAS_TEST_SUPABASE_URL?.trim();
  const serviceRoleKey = env.BOOKGOLAS_TEST_SUPABASE_SERVICE_ROLE_KEY?.trim();
  if (!url || !serviceRoleKey) {
    throw new Error("BOOKGOLAS_TEST_SUPABASE_URL and BOOKGOLAS_TEST_SUPABASE_SERVICE_ROLE_KEY are required");
  }
  const parsed = new URL(url);
  if (!new Set(["localhost", "127.0.0.1", "::1"]).has(parsed.hostname)) {
    throw new Error("disposable accounts are restricted to a local Supabase host");
  }
  return { url: parsed.toString().replace(/\/$/, ""), serviceRoleKey };
}

function adminHeaders(serviceRoleKey) {
  return {
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    "content-type": "application/json",
  };
}

export async function createDisposableAccount(prefix = "playwright") {
  const { url, serviceRoleKey } = localTestConfig();
  const id = crypto.randomUUID();
  const email = `${prefix}-${id}@local.invalid`;
  const response = await fetch(`${url}/auth/v1/admin/users`, {
    method: "POST",
    headers: adminHeaders(serviceRoleKey),
    body: JSON.stringify({
      email,
      password: crypto.randomBytes(24).toString("base64url"),
      email_confirm: true,
      user_metadata: { disposable: true, test_id: id },
    }),
  });
  if (!response.ok) {
    throw new Error(`disposable account creation failed: ${response.status} ${await response.text()}`);
  }
  const user = await response.json();
  return { id: user.id, email };
}

export async function deleteDisposableAccount(userId) {
  const { url, serviceRoleKey } = localTestConfig();
  if (!/^[0-9a-f-]{36}$/i.test(userId)) {
    throw new Error("disposable account id must be a UUID");
  }
  const response = await fetch(`${url}/auth/v1/admin/users/${encodeURIComponent(userId)}`, {
    method: "DELETE",
    headers: adminHeaders(serviceRoleKey),
  });
  if (!response.ok && response.status !== 404) {
    throw new Error(`disposable account deletion failed: ${response.status} ${await response.text()}`);
  }
}
