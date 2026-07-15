// ============================================================================
// photos Edge Function
// ============================================================================
// GET    /functions/v1/photos                一覧取得
//          ?limit=50&before=<iso>            ページング
//          ?tag=<保存値そのまま>             AI タグ完全一致検索（GIN インデックス使用）
//          ?favorite=true                    お気に入りのみ
//          ?deleted=true                     ゴミ箱一覧（deleted_at 降順・カーソルも deleted_at）
// GET    /functions/v1/photos/tags           未削除写真の AI タグ集約（頻度順・最大 100 件）
// GET    /functions/v1/photos/:id            詳細取得
// POST   /functions/v1/photos                メタデータ作成（Storage アップロードは別経路）
// POST   /functions/v1/photos/:id/restore    ゴミ箱からの復元（deleted_at = null）
// PATCH  /functions/v1/photos/:id            お気に入り・AI タグ・caption・寸法更新
// DELETE /functions/v1/photos/:id            論理削除（deleted_at = now()）
// DELETE /functions/v1/photos/:id?permanent=true  物理削除（Storage → DB の順）
//
// service_role クライアントで DB アクセスし、user_id 条件を SQL レベルで強制する。
// ============================================================================

import type { SupabaseClient } from "supabase";
import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";
import {
  aiTagsError,
  altTextError,
  captionError,
  clampLimit,
  isUuid,
  normalizeTagQuery,
  positiveIntError,
  resolvePhotosRoute,
  storagePathError,
} from "./validation.ts";

const LIST_COLUMNS =
  "id, storage_path, thumbnail_path, original_filename, file_size, width, height, exif_data, ai_tags, is_favorite, caption, alt_text, created_at";

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
  width?: number;
  height?: number;
  file_size?: number;
}

Deno.serve(async (req: Request): Promise<Response> => {
  const user = await authenticate(req);
  if (!user) return unauthorized();

  const url = new URL(req.url);
  const route = resolvePhotosRoute(url.pathname);
  if (route.kind === "unknown") {
    return jsonError(404, "NOT_FOUND", "エンドポイントが見つかりません");
  }

  const service = createServiceClient();

  try {
    switch (req.method) {
      case "GET":
        if (route.kind === "tags") return await listTags(service, user.userId);
        if (route.kind === "photo") return await getPhoto(service, user.userId, route.id);
        if (route.kind === "collection") {
          return await listPhotos(service, user.userId, url.searchParams);
        }
        break;
      case "POST": {
        if (route.kind === "restore") return await restorePhoto(service, user.userId, route.id);
        if (route.kind !== "collection") break;
        const body = await readJson<CreatePhotoBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await createPhoto(service, user.userId, body);
      }
      case "PATCH": {
        if (route.kind !== "photo") return jsonError(400, "ID_REQUIRED", "photo id が必要です");
        const body = await readJson<UpdatePhotoBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await updatePhoto(service, user.userId, route.id, body);
      }
      case "DELETE":
        if (route.kind !== "photo") return jsonError(400, "ID_REQUIRED", "photo id が必要です");
        return url.searchParams.get("permanent") === "true"
          ? await permanentDeletePhoto(service, user.userId, route.id)
          : await deletePhoto(service, user.userId, route.id);
      default:
        return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} は未対応です`);
    }
    return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} はこのパスでは未対応です`);
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
  const tag = normalizeTagQuery(params.get("tag"));
  const favoriteOnly = params.get("favorite") === "true";
  const deletedOnly = params.get("deleted") === "true";

  // ゴミ箱一覧は削除日時ベースで並べ替え・ページングする
  const orderColumn = deletedOnly ? "deleted_at" : "created_at";
  const columns = deletedOnly ? `${LIST_COLUMNS}, deleted_at` : LIST_COLUMNS;

  let query = service
    .from("photos")
    .select(columns)
    .eq("user_id", userId);

  query = deletedOnly ? query.not("deleted_at", "is", null) : query.is("deleted_at", null);
  // ai_tags は JSONB のため contains には JSON 文字列を渡す（GIN インデックスが効く）
  if (tag) query = query.contains("ai_tags", JSON.stringify([tag]));
  if (favoriteOnly) query = query.eq("is_favorite", true);

  query = query.order(orderColumn, { ascending: false }).limit(limit);

  if (before) {
    if (isNaN(new Date(before).getTime())) {
      return jsonError(400, "INVALID_QUERY", "before は ISO8601 形式で指定してください");
    }
    // next_before は Postgres の timestamptz（マイクロ秒精度）をそのまま返している。
    // Date 経由で再整形するとミリ秒に切り捨てられ、境界の行を取りこぼすため、
    // 形式検証のみ行い受信文字列をそのまま比較に使う。
    query = query.lt(orderColumn, before);
  }

  const { data, error } = await query;
  if (error) {
    console.error("listPhotos error:", error);
    return jsonError(500, "DB_ERROR", "写真一覧の取得に失敗しました");
  }

  const photos = (data ?? []) as Record<string, unknown>[];
  const nextBefore = photos.length === limit ? photos[photos.length - 1][orderColumn] : null;

  return jsonOk({ photos, next_before: nextBefore });
}

async function listTags(service: SupabaseClient, userId: string): Promise<Response> {
  // 直近 1000 件の未削除写真からタグを集約する。件数が増えたら RPC 集約に切替を検討。
  const { data, error } = await service
    .from("photos")
    .select("ai_tags")
    .eq("user_id", userId)
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(1000);

  if (error) {
    console.error("listTags error:", error);
    return jsonError(500, "DB_ERROR", "タグ一覧の取得に失敗しました");
  }

  const counts = new Map<string, number>();
  for (const row of data ?? []) {
    if (!Array.isArray(row.ai_tags)) continue;
    for (const raw of row.ai_tags) {
      if (typeof raw !== "string") continue;
      const tag = raw.trim();
      if (!tag) continue;
      counts.set(tag, (counts.get(tag) ?? 0) + 1);
    }
  }

  const tags = [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 100)
    .map(([tag]) => tag);

  return jsonOk({ tags });
}

async function getPhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  const { data, error } = await service
    .from("photos")
    .select(`${LIST_COLUMNS}, deleted_at`)
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
  const pathError = storagePathError("storage_path", body.storage_path, userId);
  if (pathError) return jsonError(400, "INVALID_REQUEST", pathError);
  if (body.thumbnail_path != null) {
    const thumbError = storagePathError("thumbnail_path", body.thumbnail_path, userId);
    if (thumbError) return jsonError(400, "INVALID_REQUEST", thumbError);
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
    .select(LIST_COLUMNS)
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
  if (Array.isArray(body.ai_tags)) {
    const tagsError = aiTagsError(body.ai_tags);
    if (tagsError) return jsonError(400, "INVALID_REQUEST", tagsError);
    updates.ai_tags = body.ai_tags;
  }
  if (typeof body.caption === "string" || body.caption === null) {
    if (typeof body.caption === "string") {
      const error = captionError(body.caption);
      if (error) return jsonError(400, "INVALID_REQUEST", error);
    }
    updates.caption = body.caption;
  }
  if (typeof body.alt_text === "string" || body.alt_text === null) {
    if (typeof body.alt_text === "string") {
      const error = altTextError(body.alt_text);
      if (error) return jsonError(400, "INVALID_REQUEST", error);
    }
    updates.alt_text = body.alt_text;
  }
  // 写真編集（トリミング等）後の寸法・サイズ更新用
  for (const field of ["width", "height", "file_size"] as const) {
    const value = body[field];
    if (value === undefined) continue;
    const error = positiveIntError(field, value);
    if (error) return jsonError(400, "INVALID_REQUEST", error);
    updates[field] = value;
  }

  if (Object.keys(updates).length === 0) {
    return jsonError(
      400,
      "INVALID_REQUEST",
      "更新可能フィールド (is_favorite, ai_tags, caption, alt_text, width, height, file_size) が指定されていません",
    );
  }

  const { data, error } = await service
    .from("photos")
    .update(updates)
    .eq("id", id)
    .eq("user_id", userId)
    .is("deleted_at", null)
    .select(LIST_COLUMNS)
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

async function restorePhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  const { data, error } = await service
    .from("photos")
    .update({ deleted_at: null })
    .eq("id", id)
    .eq("user_id", userId)
    .not("deleted_at", "is", null)
    .select(LIST_COLUMNS)
    .maybeSingle();

  if (error) {
    console.error("restorePhoto error:", error);
    return jsonError(500, "DB_ERROR", "写真の復元に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "ゴミ箱に写真が見つかりません");

  return jsonOk({ photo: data });
}

async function permanentDeletePhoto(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "photo id の形式が不正です");

  // 物理削除はゴミ箱内（論理削除済み）の写真のみ対象
  const { data: row, error: fetchError } = await service
    .from("photos")
    .select("id, storage_path, thumbnail_path")
    .eq("id", id)
    .eq("user_id", userId)
    .not("deleted_at", "is", null)
    .maybeSingle();

  if (fetchError) {
    console.error("permanentDeletePhoto fetch error:", fetchError);
    return jsonError(500, "DB_ERROR", "写真の取得に失敗しました");
  }
  if (!row) return jsonError(404, "NOT_FOUND", "ゴミ箱に写真が見つかりません");

  // Storage → DB の順で削除する。DB を先に消すと Storage 失敗時にファイルが孤児化する。
  const paths = [row.storage_path, row.thumbnail_path]
    .filter((p): p is string => typeof p === "string" && p.length > 0);
  if (paths.length > 0) {
    const { error: storageError } = await service.storage.from("photos").remove(paths);
    if (storageError) {
      console.error("permanentDeletePhoto storage error:", storageError);
      return jsonError(500, "STORAGE_ERROR", "Storage からのファイル削除に失敗しました");
    }
  }

  const { error: deleteError } = await service
    .from("photos")
    .delete()
    .eq("id", id)
    .eq("user_id", userId);

  if (deleteError) {
    console.error("permanentDeletePhoto delete error:", deleteError);
    return jsonError(500, "DB_ERROR", "写真の削除に失敗しました");
  }

  return jsonOk({ id: row.id, permanently_deleted: true });
}

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

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
