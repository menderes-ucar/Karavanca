// =========================================================
// supabase/functions/verify-purchase/index.ts
//
// KURULUM:
//   supabase functions deploy verify-purchase
//
// GEREKLİ SECRET'LAR (supabase secrets set ile eklenir):
//   GOOGLE_SERVICE_ACCOUNT_JSON  -> Play Console servis hesabı JSON'unun TAMAMI (tek satır)
//   GOOGLE_PACKAGE_NAME          -> örn: com.karavanis.app
//   APPLE_SHARED_SECRET          -> App Store Connect > Uygulama > Uygulama İçi Satın Almalar
//                                    > "Uygulamaya Özel Paylaşılan Sır"
//   (SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY zaten otomatik sağlanır)
//
// ⚠️ NOT: Google/Apple API'leri zamanla değişebilir. Production'a almadan
// önce sandbox'ta uçtan uca test et. Apple, eski "verifyReceipt" endpoint'ini
// yeni App Store Server API lehine kademeli olarak öneriyor; ilerde
// App Store Server API'ye geçiş gerekebilir.
// =========================================================

import { serve } from "https://deno.land/std@0.203.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

const GOOGLE_SERVICE_ACCOUNT_JSON = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
const GOOGLE_PACKAGE_NAME = Deno.env.get("GOOGLE_PACKAGE_NAME");
const APPLE_SHARED_SECRET = Deno.env.get("APPLE_SHARED_SECRET");

// service_role client -> RLS'i bypass eder, sadece burada (server) kullanılır.
const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    // 1) İsteği yapan kullanıcıyı doğrula (client'ın Authorization header'ı ile)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Oturum bulunamadı" }, 401);

    const userClient = createClient(SUPABASE_URL, ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userErr } = await userClient.auth.getUser();
    if (userErr || !userData?.user) {
      return json({ error: "Geçersiz oturum" }, 401);
    }
    const userId = userData.user.id;

    // 2) İstek gövdesi
    const body = await req.json();
    const platform = body.platform as string; // 'android' | 'ios'
    const productId = body.productId as string;
    const token = body.token as string; // android: purchaseToken, ios: receipt-data

    if (!platform || !productId || !token) {
      return json({ error: "Eksik parametre" }, 400);
    }

    // 3) Paketi bul (kaç kredi verilecek?)
    const packageColumn = platform === "android" ? "google_product_id" : "apple_product_id";
    const { data: pkg, error: pkgErr } = await adminClient
      .from("credit_packages")
      .select("id, credits")
      .eq(packageColumn, productId)
      .maybeSingle();

    if (pkgErr || !pkg) {
      return json({ error: "Paket bulunamadı" }, 404);
    }

    // 4) Aynı token daha önce kredilendirildi mi? (double-credit koruması)
    const { data: existing } = await adminClient
      .from("purchase_orders")
      .select("id, status")
      .eq("provider_conversation_id", token)
      .maybeSingle();

    if (existing?.status === "success") {
      return json({ ok: true, alreadyProcessed: true, newBalance: null });
    }

    // 5) Platforma göre doğrula
    let verified = false;
    let rawResponse: unknown = null;

    if (platform === "android") {
      const result = await verifyGooglePurchase(productId, token);
      verified = result.valid;
      rawResponse = result.raw;
    } else if (platform === "ios") {
      const result = await verifyApplePurchase(token, productId);
      verified = result.valid;
      rawResponse = result.raw;
    } else {
      return json({ error: "Geçersiz platform" }, 400);
    }

    if (!verified) {
      await adminClient.from("purchase_orders").insert({
        user_id: userId,
        package_id: pkg.id,
        credits: pkg.credits,
        price_kurus: 0,
        status: "failed",
        provider: platform === "android" ? "google_play" : "app_store",
        provider_conversation_id: token,
        raw_response: rawResponse,
      });
      return json({ error: "Satın alma doğrulanamadı" }, 400);
    }

    // 6) Doğrulandı -> krediyi ekle (RPC, atomik)
    const { data: newBalance, error: grantErr } = await adminClient.rpc(
      "grant_purchase_credits",
      {
        p_target_user: userId,
        p_amount: pkg.credits,
        p_reference_id: token,
      },
    );

    if (grantErr) {
      return json({ error: `Kredi eklenemedi: ${grantErr.message}` }, 500);
    }

    await adminClient.from("purchase_orders").insert({
      user_id: userId,
      package_id: pkg.id,
      credits: pkg.credits,
      price_kurus: 0,
      status: "success",
      provider: platform === "android" ? "google_play" : "app_store",
      provider_conversation_id: token,
      raw_response: rawResponse,
      completed_at: new Date().toISOString(),
    });

    return json({ ok: true, newBalance });
  } catch (e) {
    console.error("verify-purchase error:", e);
    return json({ error: String(e) }, 500);
  }
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// =========================================================
// GOOGLE PLAY DOĞRULAMA
// =========================================================
async function verifyGooglePurchase(
  productId: string,
  purchaseToken: string,
): Promise<{ valid: boolean; raw: unknown }> {
  if (!GOOGLE_SERVICE_ACCOUNT_JSON || !GOOGLE_PACKAGE_NAME) {
    console.error("Google service account / package name secret eksik");
    return { valid: false, raw: null };
  }

  const accessToken = await getGoogleAccessToken();

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${GOOGLE_PACKAGE_NAME}/purchases/products/${productId}/tokens/${purchaseToken}`;

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const data = await res.json();

  // purchaseState: 0 = satın alındı, 1 = iptal edildi, 2 = beklemede
  const valid = res.ok && data.purchaseState === 0;
  return { valid, raw: data };
}

async function getGoogleAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(GOOGLE_SERVICE_ACCOUNT_JSON!);

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encoder = new TextEncoder();
  const b64url = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const unsigned = `${b64url(header)}.${b64url(claim)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(unsigned),
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const jwt = `${unsigned}.${signatureB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenRes.ok) {
    throw new Error(`Google OAuth token alınamadı: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token as string;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const cleaned = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

// =========================================================
// APPLE DOĞRULAMA
// =========================================================
async function verifyApplePurchase(
  receiptData: string,
  productId: string,
): Promise<{ valid: boolean; raw: unknown }> {
  const verify = async (url: string) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        "receipt-data": receiptData,
        password: APPLE_SHARED_SECRET,
        "exclude-old-transactions": true,
      }),
    });
    return await res.json();
  };

  // Önce production dene, "sandbox receipt kullanıldı" hatası (21007) dönerse sandbox'a düş
  let data = await verify("https://buy.itunes.apple.com/verifyReceipt");
  if (data.status === 21007) {
    data = await verify("https://sandbox.itunes.apple.com/verifyReceipt");
  }

  if (data.status !== 0) {
    return { valid: false, raw: data };
  }

  const items = [...(data.receipt?.in_app ?? []), ...(data.latest_receipt_info ?? [])];
  const match = items.find((i: { product_id: string }) => i.product_id === productId);

  return { valid: !!match, raw: data };
}