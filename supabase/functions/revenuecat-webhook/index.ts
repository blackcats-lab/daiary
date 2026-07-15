// ============================================================================
// revenuecat-webhook Edge Function（雛形）
// ============================================================================
// POST /functions/v1/revenuecat-webhook
// RevenueCat からのサブスク状態変更通知を受け、subscriptions テーブルを同期する。
// 認証は RevenueCat 側で設定する Authorization ヘッダーで検証。
//
// Phase 2（Sprint 4）で本実装。現状は受信 + 検証骨格のみ。
// 公式仕様: https://www.revenuecat.com/docs/integrations/webhooks
// ============================================================================

import { createServiceClient } from "../_shared/auth.ts";

interface RevenueCatEvent {
  event: {
    type: string;
    app_user_id: string;
    product_id?: string;
    expiration_at_ms?: number;
    original_app_user_id?: string;
  };
  api_version: string;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonError(405, "METHOD_NOT_ALLOWED", "POST のみ受け付けます");
  }

  // ===== Webhook 認証 =====
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  const provided = req.headers.get("Authorization");
  if (!expected) {
    console.error("REVENUECAT_WEBHOOK_AUTH 未設定");
    return jsonError(500, "CONFIG_ERROR", "サーバ設定が不完全です");
  }
  if (provided !== expected) {
    return jsonError(401, "UNAUTHORIZED", "Webhook 認証に失敗しました");
  }

  let payload: RevenueCatEvent;
  try {
    payload = await req.json() as RevenueCatEvent;
  } catch {
    return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
  }

  const { event } = payload;
  if (!event?.app_user_id) {
    return jsonError(400, "INVALID_EVENT", "app_user_id が見つかりません");
  }

  // RevenueCat の匿名 ID（$RCAnonymousID:...）は auth.users にマップできない。
  // subscriptions.user_id は UUID + FK のため INSERT が必ず失敗し、非 2xx を返すと
  // RevenueCat が再送し続ける。マップ不能なイベントは 200 で ACK してスキップする。
  if (!isUuid(event.app_user_id)) {
    console.warn(`revenuecat-webhook: app_user_id が UUID ではないためスキップ: ${event.type}`);
    return new Response(JSON.stringify({ ok: true, skipped: "unmappable_app_user_id" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ===== subscriptions 更新（Phase 2 で本実装） =====
  const service = createServiceClient();

  const isActiveEvent = ["INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE", "UNCANCELLATION"]
    .includes(event.type);
  // CANCELLATION は「自動更新の停止」であり、エンタイトルメントは expires_at まで有効。
  // BILLING_ISSUE も同様に即時失効ではない（失効時は別途 EXPIRATION が届く）。
  // 即時に free へ落とすのは EXPIRATION のみとする。期限判定は getPlan 側の
  // expires_at 比較でも二重に守られる。
  const isCancelEvent = event.type === "EXPIRATION";

  if (isActiveEvent) {
    const expiresAt = event.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null;
    const { error } = await service.from("subscriptions").upsert({
      user_id: event.app_user_id,
      plan: "premium",
      expires_at: expiresAt,
      revenuecat_id: event.original_app_user_id ?? event.app_user_id,
    }, { onConflict: "user_id" });
    if (error) {
      console.error("subscriptions upsert error:", error);
      return jsonError(500, "DB_ERROR", "DB 更新に失敗しました");
    }
  } else if (isCancelEvent) {
    const { error } = await service.from("subscriptions").upsert({
      user_id: event.app_user_id,
      plan: "free",
      expires_at: null,
    }, { onConflict: "user_id" });
    if (error) {
      console.error("subscriptions cancel error:", error);
      return jsonError(500, "DB_ERROR", "DB 更新に失敗しました");
    }
  }
  // 未対応イベントはスキップ（200 を返す）

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function isUuid(s: string): boolean {
  return UUID_RE.test(s);
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
