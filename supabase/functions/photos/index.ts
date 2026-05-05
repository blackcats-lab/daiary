// ============================================================================
// photos Edge Function
// ============================================================================
// GET    /functions/v1/photos                一覧取得（ページング: ?limit=50&before=<iso>）
// GET    /functions/v1/photos/:id            詳細取得
// POST   /functions/v1/photos                メタデータ作成（Storage アップロードは別経路）
// PATCH  /functions/v1/photos/:id            お気に入り・AI タグ更新
// DELETE /functions/v1/photos/:id            論理削除（deleted_at = now()）
//
// service_role クライアントで DB アクセスし、user_id 条件を SQL レベルで強制する。
// ============================================================================

import type { SupabaseClient } from "supabase";
import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 100;

interface CreatePhotoBody {
  storage_path: string;
  thumbnail_path?: string | null;
  original_filename?: string | null;
  file_size?: number | null;
  width?: number | null;
  height?: number | null;
  exif_data?: Record<string, unknown>;
  ai_tags?: unknown[];
}

interface UpdatePhotoBody {
  is_favorite?: boolean;
  ai_tags?: unknown[];
  caption?: string | null;
  alt_text?: string | null;
}

Deno.serve(async (req: Request): Promise<Response> => {
  const user = await authenticate(req);
  if (!user) return unauthorized();

  const url = new URL(req.url);
  const segments = url.pathname.split("/").filter(Boolean);
  // パス末尾が "photos" なら一覧、それ以外は ID 指定
  const photoId = segments[segments.length - 1] !== "photos" ? segments[segments.length - 1] : null;

  const service = createServiceClient();

  try {
    switch (req.method) {
      case "GET":
        return photoId
          ? await getPhoto(service, user.userId, photoId)
          : await listPhotos(service, user.userId, url.searchParams);
      case "POST": {
        const body = await readJson<CreatePhotoBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await createPhoto(service, user.userId, body);
      }
      case "PATCH": {
        if (!photoId) return jsonError(400, "ID_REQUIRED", "photo id が必要です");
        const body = await readJson<UpdatePhotoBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await updatePhoto(service, user.userId, photoId, body);
      }
      case "DELETE":
        if (!photoId) return jsonError(400, "ID_REQUIRED", "photo id が必要です");
        return await deletePhoto(service, user.userId, photoId);
      default:
        return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} は未対応です`);
    }
  } catch (e) {
    console.error("photos handler error:", e);
    return jsonError(500, "INTERNAL_ERROR", "サーバ内部エラー");
  }
});

// ----------------------------------------------------------------------------
// Handlers
// ----------------------------------------------------------------------------

async function listPhotos(
  service: SupabaseClient,
  userId: string,
  params: URLSearchParams,
): Promise<Response> {
  const limit = clampLimit(Number(params.get("limit")));
  const before = params.get("before");

  let query = service
    .from("photos")
    .select(
      "id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite, caption, alt_text, created_at",
    )
    .eq("user_id", userId)
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (before) {
    const date = new Date(before);
    if (isNaN(date.getTime())) {
      return jsonError(400, "INVALID_QUERY", "before は ISO8601 形式で指定してください");
    }
    query = query.lt("created_at", date.toISOString());
  }

  const { data, error } = await query;
  if (error) {
    console.error("listPhotos error:", error);
    return jsonError(500, "DB_ERROR", "写真一覧の取得に失敗しました");
  }

  const photos = data ?? [];
  const nextBefore = photos.length === limit ? photos[photos.length - 1].created_at : null;

  return jsonOk({ photos, next_before: nextBefore });
}

async function getPhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  const { data, error } = await service
    .from("photos")
    .select(
      "id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite, caption, alt_text, created_at, deleted_at",
    )
    .eq("id", id)
    .eq("user_id", userId)
    .is("deleted_at", null)
    .maybeSingle();

  if (error) {
    console.error("getPhoto error:", error);
    return jsonError(500, "DB_ERROR", "写真の取得に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "写真が見つかりません");

  return jsonOk({ photo: data });
}

async function createPhoto(
  service: SupabaseClient,
  userId: string,
  body: CreatePhotoBody,
): Promise<Response> {
  if (!body.storage_path || typeof body.storage_path !== "string") {
    return jsonError(400, "INVALID_REQUEST", "storage_path は必須です");
  }

  const insertRow = {
    user_id: userId,
    storage_path: body.storage_path,
    thumbnail_path: body.thumbnail_path ?? null,
    original_filename: body.original_filename ?? null,
    file_size: body.file_size ?? null,
    width: body.width ?? null,
    height: body.height ?? null,
    exif_data: body.exif_data ?? {},
    ai_tags: body.ai_tags ?? [],
  };

  const { data, error } = await service
    .from("photos")
    .insert(insertRow)
    .select(
      "id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite, caption, alt_text, created_at",
    )
    .single();

  if (error) {
    console.error("createPhoto error:", error);
    return jsonError(500, "DB_ERROR", "写真の作成に失敗しました");
  }

  return new Response(
    JSON.stringify({ photo: data }),
    { status: 201, headers: { "Content-Type": "application/json" } },
  );
}

async function updatePhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
  body: UpdatePhotoBody,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  const updates: Record<string, unknown> = {};
  if (typeof body.is_favorite === "boolean") updates.is_favorite = body.is_favorite;
  if (Array.isArray(body.ai_tags)) updates.ai_tags = body.ai_tags;
  if (typeof body.caption === "string" || body.caption === null) {
    updates.caption = body.caption;
  }
  if (typeof body.alt_text === "string" || body.alt_text === null) {
    updates.alt_text = body.alt_text;
  }

  if (Object.keys(updates).length === 0) {
    return jsonError(
      400,
      "INVALID_REQUEST",
      "更新可能フィールド (is_favorite, ai_tags, caption, alt_text) が指定されていません",
    );
  }

  const { data, error } = await service
    .from("photos")
    .update(updates)
    .eq("id", id)
    .eq("user_id", userId)
    .is("deleted_at", null)
    .select(
      "id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite, caption, alt_text, created_at",
    )
    .maybeSingle();

  if (error) {
    console.error("updatePhoto error:", error);
    return jsonError(500, "DB_ERROR", "写真の更新に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "写真が見つかりません");

  return jsonOk({ photo: data });
}

async function deletePhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  const { data, error } = await service
    .from("photos")
    .update({ deleted_at: new Date().toISOString() })
    .eq("id", id)
    .eq("user_id", userId)
    .is("deleted_at", null)
    .select("id")
    .maybeSingle();

  if (error) {
    console.error("deletePhoto error:", error);
    return jsonError(500, "DB_ERROR", "写真の削除に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "写真が見つかりません");

  return jsonOk({ id: data.id, deleted: true });
}

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

function clampLimit(value: number): number {
  if (!Number.isFinite(value) || value <= 0) return DEFAULT_LIMIT;
  return Math.min(Math.floor(value), MAX_LIMIT);
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function isUuid(s: string): boolean {
  return UUID_RE.test(s);
}

async function readJson<T>(req: Request): Promise<T | null> {
  try {
    return await req.json() as T;
  } catch {
    return null;
  }
}

function jsonOk(body: Record<string, unknown>): Response {
  return new Response(
    JSON.stringify(body),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
