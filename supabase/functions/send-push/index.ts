// send-push — Edge Function sending Firebase Cloud Messaging pushes.
//
// The Firebase service-account JSON lives ONLY in `supabase secrets`
// (FIREBASE_SERVICE_ACCOUNT); the APK never sees it. Clients call this with
// their normal Supabase JWT and may only push to their own user id.
// Deploy: supabase functions deploy send-push
// Secret:  supabase secrets set FIREBASE_SERVICE_ACCOUNT='<minified json>'
//
// Flow: service account -> OAuth2 access token (JWT bearer grant, cached)
//       -> FCM HTTP v1 messages:send for each registered device token.
// Stale tokens that FCM reports as unregistered are deleted.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SA_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

// ---------- Google OAuth2 (JWT bearer grant) ----------

let cachedToken: { value: string; expiresAt: number } | null = null;

function b64url(input: string | ArrayBuffer): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

async function signJwt(sa: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: FCM_SCOPE,
      aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  return `${unsigned}.${b64url(sig)}`;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem
    .replaceAll("-----BEGIN PRIVATE KEY-----", "")
    .replaceAll("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

async function accessToken(sa: {
  client_email: string;
  private_key: string;
  token_uri?: string;
}): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) {
    return cachedToken.value;
  }
  const assertion = await signJwt(sa);
  const res = await fetch(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`oauth_${res.status}`);
  const data = await res.json();
  cachedToken = {
    value: data.access_token,
    expiresAt: Date.now() + (data.expires_in ?? 3600) * 1000,
  };
  return cachedToken.value;
}

// ---------- FCM send ----------

async function sendToToken(
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
  bearer: string,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${bearer}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: { priority: "HIGH" },
        },
      }),
    },
  );
  if (res.ok) return { ok: true, unregistered: false };
  const text = await res.text();
  const unregistered =
    res.status === 404 || text.includes("UNREGISTERED") || text.includes("NOT_FOUND");
  return { ok: false, unregistered };
}

// ---------- handler ----------

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!SA_JSON || !SUPABASE_URL || !SERVICE_ROLE) {
    return json({ error: "push_not_configured" }, 503);
  }

  // Caller identity: the gateway already verified the JWT signature.
  const auth = req.headers.get("Authorization") ?? "";
  const jwt = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  let callerId = "";
  try {
    callerId = JSON.parse(atob(jwt.split(".")[1])).sub ?? "";
  } catch (_) {}
  if (!callerId) return json({ error: "unauthorized" }, 401);

  let payload: {
    user_id?: string;
    title?: string;
    body?: string;
    data?: Record<string, string>;
  };
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: "bad_json" }, 400);
  }

  const userId = payload.user_id ?? callerId;
  const title = (payload.title ?? "").slice(0, 100);
  const body = (payload.body ?? "").slice(0, 500);
  if (!userId || !title || !body) return json({ error: "missing_fields" }, 400);
  // Users may only push to their own devices.
  if (userId !== callerId) return json({ error: "forbidden" }, 403);

  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries(payload.data ?? {})) {
    if (typeof v === "string" && k.length <= 50) data[k.slice(0, 50)] = v.slice(0, 200);
  }

  try {
    const sa = JSON.parse(SA_JSON);
    const projectId = sa.project_id as string;

    // Fetch this user's device tokens (service role bypasses RLS).
    const tokRes = await fetch(
      `${SUPABASE_URL}/rest/v1/push_tokens?user_id=eq.${encodeURIComponent(userId)}&select=token`,
      {
        headers: {
          apikey: SERVICE_ROLE,
          Authorization: `Bearer ${SERVICE_ROLE}`,
        },
      },
    );
    if (!tokRes.ok) return json({ error: "token_lookup_failed" }, 502);
    const rows = (await tokRes.json()) as { token: string }[];
    if (rows.length === 0) return json({ sent: 0, reason: "no_devices" });

    const bearer = await accessToken(sa);
    let sent = 0;
    const stale: string[] = [];
    for (const row of rows) {
      const r = await sendToToken(projectId, row.token, title, body, data, bearer);
      if (r.ok) sent++;
      else if (r.unregistered) stale.push(row.token);
    }
    if (stale.length > 0) {
      await fetch(
        `${SUPABASE_URL}/rest/v1/push_tokens?user_id=eq.${encodeURIComponent(userId)}&token=in.(${stale.map(encodeURIComponent).join(",")})`,
        {
          method: "DELETE",
          headers: {
            apikey: SERVICE_ROLE,
            Authorization: `Bearer ${SERVICE_ROLE}`,
          },
        },
      );
    }
    return json({ sent, stale_removed: stale.length });
  } catch (e) {
    return json({ error: "send_failed" }, 502);
  }
});
