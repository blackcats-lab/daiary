// ============================================================================
// 認証ヘルパー
// ============================================================================
// Authorization ヘッダーから JWT を取り出し、Supabase Auth で検証して
// user_id を取得する。失敗時は 401 を返す Response を生成する。
// ============================================================================

import { createClient, type SupabaseClient } from "supabase";

export interface AuthenticatedUser {
  userId: string;
  jwt: string;
}

/**
 * リクエストヘッダーから JWT を抽出。
 * 形式: `Authorization: Bearer <token>`
 */
export function extractJwt(req: Request): string | null {
  const header = req.headers.get("Authorization");
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

/**
 * JWT を検証して user_id を返す。
 * 検証は Supabase Auth API（getUser）で行う。
 */
export async function authenticate(req: Request): Promise<AuthenticatedUser | null> {
  const jwt = extractJwt(req);
  if (!jwt) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!supabaseUrl || !supabaseAnonKey) {
    console.error("SUPABASE_URL / SUPABASE_ANON_KEY が未設定");
    return null;
  }

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false },
  });

  const { data, error } = await client.auth.getUser(jwt);
  if (error || !data.user) return null;

  return { userId: data.user.id, jwt };
}

/**
 * service_role 権限の Supabase クライアントを生成。
 * RLS をバイパスするため Edge Function 内の特権操作のみで使用すること。
 */
export function createServiceClient(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY が未設定");
  }
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function unauthorized(message = "Unauthorized"): Response {
  return new Response(
    JSON.stringify({ code: "UNAUTHORIZED", message }),
    { status: 401, headers: { "Content-Type": "application/json" } },
  );
}
