import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const FIREBASE_SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");

async function getFcmAccessToken(): Promise<string> {
  const { client_email, private_key } = FIREBASE_SERVICE_ACCOUNT;
  const jose = await import("https://deno.land/x/jose@v4.14.4/index.ts");

  const now = Math.floor(Date.now() / 1000);
  const jwt = await new jose.SignJWT({
    iss: client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  })
    .setProtectedHeader({ alg: "RS256" })
    .sign(await jose.importPKCS8(private_key, "RS256"));

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await res.json();
  return data.access_token;
}

serve(async (req) => {
  try {
    const { target_user_id, title, body } = await req.json();

    if (!target_user_id) {
      return new Response("target_user_id eksik", { status: 400 });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: tokens, error } = await supabaseAdmin
      .from("user_push_tokens")
      .select("fcm_token")
      .eq("user_id", target_user_id);

    if (error || !tokens || tokens.length === 0) {
      return new Response("Token bulunamadı", { status: 200 });
    }

    const accessToken = await getFcmAccessToken();
    const projectId = FIREBASE_SERVICE_ACCOUNT.project_id;

    for (const row of tokens) {
      await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: row.fcm_token,
            notification: { title, body },
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default" } } }
          },
        }),
      });
    }

    return new Response(JSON.stringify({ success: true }), { headers: { "Content-Type": "application/json" } });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});