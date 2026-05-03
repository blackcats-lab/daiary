// ============================================================================
// 利用回数管理ヘルパー
// ============================================================================
// プラン取得 / 当日カウント取得 / increment_usage 呼び出し / usage_logs 挿入。
// 全て service_role の Supabase クライアントを引数に取る。
// ============================================================================

import type { SupabaseClient } from "supabase";
import type { Plan, UsageContext } from "./types.ts";

/** プランごとの 1 日あたり利用上限 */
export const DAILY_LIMITS: Record<Plan, number> = {
  free: 5,
  premium: 100,
};

/**
 * subscriptions から plan を取得。行が無ければ free 扱い。
 */
export async function getPlan(client: SupabaseClient, userId: string): Promise<Plan> {
  const { data, error } = await client
    .from("subscriptions")
    .select("plan, expires_at")
    .eq("user_id", userId)
    .maybeSingle();

  if (error) {
    console.error("getPlan error:", error);
    return "free";
  }
  if (!data) return "free";

  if (data.plan === "premium") {
    const expiresAt = data.expires_at ? new Date(data.expires_at).getTime() : 0;
    if (expiresAt > Date.now()) return "premium";
  }
  return "free";
}

/** 当日のこれまでの利用回数を取得。行が無ければ 0。 */
export async function getTodayCount(client: SupabaseClient, userId: string): Promise<number> {
  const today = new Date().toISOString().slice(0, 10);
  const { data, error } = await client
    .from("daily_usage")
    .select("count")
    .eq("user_id", userId)
    .eq("usage_date", today)
    .maybeSingle();

  if (error) {
    console.error("getTodayCount error:", error);
    return 0;
  }
  return data?.count ?? 0;
}

/** プラン + 当日カウント + 上限をまとめて取得 */
export async function loadUsageContext(
  client: SupabaseClient,
  userId: string,
): Promise<UsageContext> {
  const [plan, todayCount] = await Promise.all([
    getPlan(client, userId),
    getTodayCount(client, userId),
  ]);
  return { userId, plan, todayCount, dailyLimit: DAILY_LIMITS[plan] };
}

/**
 * increment_usage RPC を呼ぶ。AI 生成成功時のみ呼び出すこと。
 * 戻り値は更新後の当日カウント。
 */
export async function incrementUsage(
  client: SupabaseClient,
  userId: string,
): Promise<number> {
  const { data, error } = await client.rpc("increment_usage", { p_user_id: userId });
  if (error) {
    console.error("incrementUsage error:", error);
    throw error;
  }
  return data as number;
}

/** usage_logs に 1 行挿入 */
export async function logUsage(
  client: SupabaseClient,
  params: {
    userId: string;
    model: string;
    inputTokens: number;
    outputTokens: number;
    costUsd: number;
  },
): Promise<void> {
  const { error } = await client.from("usage_logs").insert({
    user_id: params.userId,
    model: params.model,
    input_tokens: params.inputTokens,
    output_tokens: params.outputTokens,
    cost_usd: params.costUsd,
  });
  if (error) {
    console.error("logUsage error:", error);
    // ログ失敗は致命傷ではないため throw しない
  }
}

export function rateLimited(remaining: number, limit: number): Response {
  return new Response(
    JSON.stringify({
      code: "RATE_LIMITED",
      message: "本日の利用上限に達しました",
      remaining,
      limit,
    }),
    {
      status: 429,
      headers: {
        "Content-Type": "application/json",
        "X-RateLimit-Limit": String(limit),
        "X-RateLimit-Remaining": String(remaining),
      },
    },
  );
}
