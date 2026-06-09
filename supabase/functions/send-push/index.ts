import { createClient } from "https://esm.sh/@supabase/supabase-js@2.46.1";

type PushBody = {
  title?: string;
  body?: string;
  userId?: string;
  data?: Record<string, string>;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function base64UrlEncode(input: string | ArrayBuffer) {
  const bytes =
    typeof input === "string"
      ? new TextEncoder().encode(input)
      : new Uint8Array(input);

  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);

  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

function pemToArrayBuffer(pem: string) {
  const clean = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\\n/g, "")
    .replace(/\n/g, "")
    .trim();

  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);

  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }

  return bytes.buffer;
}

async function createGoogleAccessToken() {
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY");

  if (!clientEmail || !privateKey) {
    throw new Error("FCM_CLIENT_EMAIL veya FCM_PRIVATE_KEY eksik.");
  }

  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const payload = {
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const unsignedJwt =
    `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(payload))}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(privateKey),
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsignedJwt),
  );

  const jwt = `${unsignedJwt}.${base64UrlEncode(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();

  if (!res.ok) {
    throw new Error(`Google token alınamadı: ${JSON.stringify(data)}`);
  }

  return data.access_token as string;
}

async function sendFcmToToken(params: {
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}) {
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  if (!projectId) throw new Error("FCM_PROJECT_ID eksik.");

  const accessToken = await createGoogleAccessToken();

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: params.token,
          notification: {
            title: params.title,
            body: params.body,
          },
          data: params.data,
          android: {
            priority: "HIGH",
            notification: {
              channel_id: "karavanis_default",
              sound: "default",
            },
          },
        },
      }),
    },
  );

  const data = await res.json();

  return {
    ok: res.ok,
    status: res.status,
    response: data,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Only POST allowed" }, 405);
  }

  try {
    const body = (await req.json()) as PushBody;

    const title = body.title?.trim() || "Karavanis";
    const messageBody = body.body?.trim() || "Yeni bildirimin var.";
    const targetUserId = body.userId?.trim();

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("SUPABASE_URL veya SUPABASE_SERVICE_ROLE_KEY eksik.");
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    let query = supabase
      .from("user_push_tokens")
      .select("user_id,fcm_token,platform");

    if (targetUserId) {
      query = query.eq("user_id", targetUserId);
    }

    const { data: tokens, error } = await query;

    if (error) throw error;

    if (!tokens || tokens.length === 0) {
      return json({
        ok: false,
        sent: 0,
        message: "Kayıtlı FCM token bulunamadı.",
      });
    }

    const results = [];

    for (const row of tokens) {
      const result = await sendFcmToToken({
        token: row.fcm_token,
        title,
        body: messageBody,
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          source: "supabase",
          ...(body.data ?? {}),
        },
      });

      results.push({
        userId: row.user_id,
        ok: result.ok,
        status: result.status,
        response: result.response,
      });
    }

    return json({
      ok: true,
      sent: results.filter((r) => r.ok).length,
      total: results.length,
      results,
    });
  } catch (e) {
    console.error("SEND_PUSH_ERROR", e);

    return json({
      ok: false,
      error: e instanceof Error ? e.message : JSON.stringify(e),
      raw: String(e),
    }, 500);
  }
});