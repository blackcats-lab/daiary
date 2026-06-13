// ============================================================================
// albums Edge Function
// ============================================================================
// GET    /functions/v1/albums                       一覧取得
// GET    /functions/v1/albums/:id                   詳細取得（写真リスト含む）
// POST   /functions/v1/albums                       作成
// PATCH  /functions/v1/albums/:id                   編集
// DELETE /functions/v1/albums/:id                   削除（CASCADE で album_photos も消える）
// POST   /functions/v1/albums/:id/photos            写真を一括追加（photo_ids 配列）
// DELETE /functions/v1/albums/:id/photos            写真を一括削除（photo_ids 配列）
//
// service_role クライアントで DB アクセスし、user_id 条件を SQL レベルで強制する。
// album_photos の RLS は二重 EXISTS なので、Edge Function 側で「写真の所有者と
// アルバムの所有者が一致」を SQL ガードでも明示的に確認する。
// ============================================================================

import type { SupabaseClient } from "supabase";
import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";

/** 一度に追加・削除できる写真の上限 */
const MAX_PHOTOS_PER_BATCH = 100;

interface CreateAlbumBody {
  name: string;
  cover_photo_id?: string | null;
  is_public?: boolean;
}

interface UpdateAlbumBody {
  name?: string;
  cover_photo_id?: string | null;
  is_public?: boolean;
  share_token?: string | null;
}

interface PhotoBatchBody {
  photo_ids: string[];
}

Deno.serve(async (req: Request): Promise<Response> => {
  const user = await authenticate(req);
  if (!user) return unauthorized();

  const url = new URL(req.url);
  const segs = url.pathname.split("/").filter(Boolean);
  const albumsIdx = segs.lastIndexOf("albums");
  const albumId = segs[albumsIdx + 1] ?? null;
  const subRes = segs[albumsIdx + 2] ?? null;

  if (subRes !== null && subRes !== "photos") {
    return jsonError(404, "NOT_FOUND", "リソースが見つかりません");
  }

  const service = createServiceClient();

  try {
    switch (req.method) {
      case "GET":
        if (subRes === "photos") {
          return jsonError(405, "METHOD_NOT_ALLOWED", "GET /albums/:id/photos は未対応です");
        }
        return albumId
          ? await getAlbum(service, user.userId, albumId)
          : await listAlbums(service, user.userId);
      case "POST": {
        if (subRes === "photos") {
          if (!albumId) return jsonError(400, "ID_REQUIRED", "album id が必要です");
          const body = await readJson<PhotoBatchBody>(req);
          if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
          return await addPhotosToAlbum(service, user.userId, albumId, body);
        }
        if (albumId) return jsonError(405, "METHOD_NOT_ALLOWED", "POST /albums/:id は未対応です");
        const body = await readJson<CreateAlbumBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await createAlbum(service, user.userId, body);
      }
      case "PATCH": {
        if (subRes === "photos") {
          return jsonError(405, "METHOD_NOT_ALLOWED", "PATCH /albums/:id/photos は未対応です");
        }
        if (!albumId) return jsonError(400, "ID_REQUIRED", "album id が必要です");
        const body = await readJson<UpdateAlbumBody>(req);
        if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
        return await updateAlbum(service, user.userId, albumId, body);
      }
      case "DELETE": {
        if (!albumId) return jsonError(400, "ID_REQUIRED", "album id が必要です");
        if (subRes === "photos") {
          const body = await readJson<PhotoBatchBody>(req);
          if (!body) return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
          return await removePhotosFromAlbum(service, user.userId, albumId, body);
        }
        return await deleteAlbum(service, user.userId, albumId);
      }
      default:
        return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} は未対応です`);
    }
  } catch (e) {
    console.error("albums handler error:", e);
    return jsonError(500, "INTERNAL_ERROR", "サーバ内部エラー");
  }
});

// ----------------------------------------------------------------------------
// Handlers
// ----------------------------------------------------------------------------

async function listAlbums(
  service: SupabaseClient,
  userId: string,
): Promise<Response> {
  const { data, error } = await service
    .from("albums")
    .select(
      `id, name, cover_photo_id, is_public, share_token, created_at, updated_at,
       cover_photo:photos!albums_cover_photo_id_fkey(thumbnail_path),
       album_photos(count)`,
    )
    .eq("user_id", userId)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("listAlbums error:", error);
    return jsonError(500, "DB_ERROR", "アルバム一覧の取得に失敗しました");
  }

  const albums = (data ?? []).map((row: Record<string, unknown>) => {
    const cover = row.cover_photo as { thumbnail_path?: string | null } | null;
    const counts = row.album_photos as Array<{ count: number }> | null;
    return {
      id: row.id,
      name: row.name,
      cover_photo_id: row.cover_photo_id,
      cover_thumbnail_path: cover?.thumbnail_path ?? null,
      is_public: row.is_public,
      share_token: row.share_token,
      photo_count: counts?.[0]?.count ?? 0,
      created_at: row.created_at,
      updated_at: row.updated_at,
    };
  });

  return jsonOk({ albums });
}

async function getAlbum(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "album id の形式が不正です");

  const { data: album, error: albumError } = await service
    .from("albums")
    .select(
      "id, name, cover_photo_id, is_public, share_token, created_at, updated_at",
    )
    .eq("id", id)
    .eq("user_id", userId)
    .maybeSingle();

  if (albumError) {
    console.error("getAlbum error:", albumError);
    return jsonError(500, "DB_ERROR", "アルバムの取得に失敗しました");
  }
  if (!album) return jsonError(404, "NOT_FOUND", "アルバムが見つかりません");

  const { data: rows, error: photosError } = await service
    .from("album_photos")
    .select(
      `sort_order, added_at,
       photo:photos!inner(id, storage_path, thumbnail_path, width, height,
                          caption, ai_tags, is_favorite, deleted_at)`,
    )
    .eq("album_id", id)
    .order("sort_order", { ascending: true })
    .order("added_at", { ascending: false });

  if (photosError) {
    console.error("getAlbum photos error:", photosError);
    return jsonError(500, "DB_ERROR", "アルバム内の写真取得に失敗しました");
  }

  const photos = (rows ?? [])
    .map((row: Record<string, unknown>) => {
      const photo = row.photo as Record<string, unknown> | null;
      if (!photo || photo.deleted_at !== null) return null;
      return {
        id: photo.id,
        storage_path: photo.storage_path,
        thumbnail_path: photo.thumbnail_path,
        width: photo.width,
        height: photo.height,
        caption: photo.caption,
        ai_tags: photo.ai_tags ?? [],
        is_favorite: photo.is_favorite,
        sort_order: row.sort_order,
        added_at: row.added_at,
      };
    })
    .filter((p) => p !== null);

  return jsonOk({ album, photos });
}

async function createAlbum(
  service: SupabaseClient,
  userId: string,
  body: CreateAlbumBody,
): Promise<Response> {
  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (name.length === 0 || name.length > 100) {
    return jsonError(400, "INVALID_REQUEST", "name は 1〜100 字で指定してください");
  }

  if (body.cover_photo_id != null) {
    if (!isUuid(body.cover_photo_id)) {
      return jsonError(400, "INVALID_REQUEST", "cover_photo_id の形式が不正です");
    }
    const ok = await isPhotoOwnedByUser(service, body.cover_photo_id, userId);
    if (!ok) return jsonError(400, "INVALID_REQUEST", "cover_photo_id が無効です");
  }

  const insertRow = {
    user_id: userId,
    name,
    cover_photo_id: body.cover_photo_id ?? null,
    is_public: body.is_public ?? false,
  };

  const { data, error } = await service
    .from("albums")
    .insert(insertRow)
    .select(
      "id, name, cover_photo_id, is_public, share_token, created_at, updated_at",
    )
    .single();

  if (error) {
    console.error("createAlbum error:", error);
    return jsonError(500, "DB_ERROR", "アルバムの作成に失敗しました");
  }

  const album = {
    ...data,
    cover_thumbnail_path: null,
    photo_count: 0,
  };

  return new Response(
    JSON.stringify({ album }),
    { status: 201, headers: { "Content-Type": "application/json" } },
  );
}

async function updateAlbum(
  service: SupabaseClient,
  userId: string,
  id: string,
  body: UpdateAlbumBody,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "album id の形式が不正です");

  const updates: Record<string, unknown> = {};

  if (typeof body.name === "string") {
    const name = body.name.trim();
    if (name.length === 0 || name.length > 100) {
      return jsonError(400, "INVALID_REQUEST", "name は 1〜100 字で指定してください");
    }
    updates.name = name;
  }

  if ("cover_photo_id" in body) {
    if (body.cover_photo_id === null) {
      updates.cover_photo_id = null;
    } else if (typeof body.cover_photo_id === "string") {
      if (!isUuid(body.cover_photo_id)) {
        return jsonError(400, "INVALID_REQUEST", "cover_photo_id の形式が不正です");
      }
      const ok = await isPhotoOwnedByUser(service, body.cover_photo_id, userId);
      if (!ok) return jsonError(400, "INVALID_REQUEST", "cover_photo_id が無効です");
      updates.cover_photo_id = body.cover_photo_id;
    }
  }

  if (typeof body.is_public === "boolean") updates.is_public = body.is_public;

  if ("share_token" in body) {
    if (body.share_token === null || typeof body.share_token === "string") {
      updates.share_token = body.share_token;
    }
  }

  if (Object.keys(updates).length === 0) {
    return jsonError(
      400,
      "INVALID_REQUEST",
      "更新可能フィールド (name, cover_photo_id, is_public, share_token) が指定されていません",
    );
  }

  const { data, error } = await service
    .from("albums")
    .update(updates)
    .eq("id", id)
    .eq("user_id", userId)
    .select(
      "id, name, cover_photo_id, is_public, share_token, created_at, updated_at",
    )
    .maybeSingle();

  if (error) {
    console.error("updateAlbum error:", error);
    return jsonError(500, "DB_ERROR", "アルバムの更新に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "アルバムが見つかりません");

  return jsonOk({ album: data });
}

async function deleteAlbum(
  service: SupabaseClient,
  userId: string,
  id: string,
): Promise<Response> {
  if (!isUuid(id)) return jsonError(400, "INVALID_ID", "album id の形式が不正です");

  const { data, error } = await service
    .from("albums")
    .delete()
    .eq("id", id)
    .eq("user_id", userId)
    .select("id")
    .maybeSingle();

  if (error) {
    console.error("deleteAlbum error:", error);
    return jsonError(500, "DB_ERROR", "アルバムの削除に失敗しました");
  }
  if (!data) return jsonError(404, "NOT_FOUND", "アルバムが見つかりません");

  return jsonOk({ id: data.id, deleted: true });
}

async function addPhotosToAlbum(
  service: SupabaseClient,
  userId: string,
  albumId: string,
  body: PhotoBatchBody,
): Promise<Response> {
  if (!isUuid(albumId)) return jsonError(400, "INVALID_ID", "album id の形式が不正です");

  const ids = body.photo_ids;
  if (!Array.isArray(ids) || ids.length === 0) {
    return jsonError(400, "INVALID_REQUEST", "photo_ids は 1 件以上の配列で指定してください");
  }
  if (ids.length > MAX_PHOTOS_PER_BATCH) {
    return jsonError(
      400,
      "INVALID_REQUEST",
      `一度に追加できるのは ${MAX_PHOTOS_PER_BATCH} 件までです`,
    );
  }
  for (const pid of ids) {
    if (typeof pid !== "string" || !isUuid(pid)) {
      return jsonError(400, "INVALID_ID", "photo_ids に不正な UUID が含まれます");
    }
  }

  // album 所有確認
  const { data: album, error: albumError } = await service
    .from("albums")
    .select("id")
    .eq("id", albumId)
    .eq("user_id", userId)
    .maybeSingle();
  if (albumError) {
    console.error("addPhotosToAlbum album check error:", albumError);
    return jsonError(500, "DB_ERROR", "アルバムの確認に失敗しました");
  }
  if (!album) return jsonError(404, "NOT_FOUND", "アルバムが見つかりません");

  // 自分の未削除写真のみ採用
  const uniqueIds = Array.from(new Set(ids));
  const { data: ownedRows, error: photoError } = await service
    .from("photos")
    .select("id")
    .in("id", uniqueIds)
    .eq("user_id", userId)
    .is("deleted_at", null);
  if (photoError) {
    console.error("addPhotosToAlbum photo check error:", photoError);
    return jsonError(500, "DB_ERROR", "写真の確認に失敗しました");
  }
  const ownedSet = new Set((ownedRows ?? []).map((r: { id: string }) => r.id));

  // 既存の中間レコードを取得（重複弾き）
  const { data: existingRows, error: existingError } = await service
    .from("album_photos")
    .select("photo_id")
    .eq("album_id", albumId)
    .in("photo_id", uniqueIds);
  if (existingError) {
    console.error("addPhotosToAlbum existing check error:", existingError);
    return jsonError(500, "DB_ERROR", "既存の関連付けの確認に失敗しました");
  }
  const existingSet = new Set(
    (existingRows ?? []).map((r: { photo_id: string }) => r.photo_id),
  );

  const skipped: Array<{ photo_id: string; reason: string }> = [];
  const insertable: string[] = [];
  for (const pid of uniqueIds) {
    if (!ownedSet.has(pid)) {
      skipped.push({ photo_id: pid, reason: "not_owned_or_deleted" });
    } else if (existingSet.has(pid)) {
      skipped.push({ photo_id: pid, reason: "already_in_album" });
    } else {
      insertable.push(pid);
    }
  }

  if (insertable.length === 0) {
    return jsonOk({ added: [], skipped });
  }

  // sort_order 計算
  const { data: maxRow, error: maxError } = await service
    .from("album_photos")
    .select("sort_order")
    .eq("album_id", albumId)
    .order("sort_order", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (maxError) {
    console.error("addPhotosToAlbum max sort_order error:", maxError);
    return jsonError(500, "DB_ERROR", "並び順の計算に失敗しました");
  }
  const baseOrder = (maxRow?.sort_order ?? -1) + 1;

  const rows = insertable.map((pid, i) => ({
    album_id: albumId,
    photo_id: pid,
    sort_order: baseOrder + i,
  }));

  const { error: insertError } = await service.from("album_photos").insert(rows);
  if (insertError) {
    console.error("addPhotosToAlbum insert error:", insertError);
    return jsonError(500, "DB_ERROR", "アルバムへの追加に失敗しました");
  }

  return jsonOk({ added: insertable, skipped });
}

async function removePhotosFromAlbum(
  service: SupabaseClient,
  userId: string,
  albumId: string,
  body: PhotoBatchBody,
): Promise<Response> {
  if (!isUuid(albumId)) return jsonError(400, "INVALID_ID", "album id の形式が不正です");

  const ids = body.photo_ids;
  if (!Array.isArray(ids) || ids.length === 0) {
    return jsonError(400, "INVALID_REQUEST", "photo_ids は 1 件以上の配列で指定してください");
  }
  if (ids.length > MAX_PHOTOS_PER_BATCH) {
    return jsonError(
      400,
      "INVALID_REQUEST",
      `一度に削除できるのは ${MAX_PHOTOS_PER_BATCH} 件までです`,
    );
  }
  for (const pid of ids) {
    if (typeof pid !== "string" || !isUuid(pid)) {
      return jsonError(400, "INVALID_ID", "photo_ids に不正な UUID が含まれます");
    }
  }

  const { data: album, error: albumError } = await service
    .from("albums")
    .select("id")
    .eq("id", albumId)
    .eq("user_id", userId)
    .maybeSingle();
  if (albumError) {
    console.error("removePhotosFromAlbum album check error:", albumError);
    return jsonError(500, "DB_ERROR", "アルバムの確認に失敗しました");
  }
  if (!album) return jsonError(404, "NOT_FOUND", "アルバムが見つかりません");

  const { data, error } = await service
    .from("album_photos")
    .delete()
    .eq("album_id", albumId)
    .in("photo_id", ids)
    .select("photo_id");

  if (error) {
    console.error("removePhotosFromAlbum error:", error);
    return jsonError(500, "DB_ERROR", "アルバムからの削除に失敗しました");
  }

  const removed = (data ?? []).map((r: { photo_id: string }) => r.photo_id);
  return jsonOk({ removed });
}

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------

async function isPhotoOwnedByUser(
  service: SupabaseClient,
  photoId: string,
  userId: string,
): Promise<boolean> {
  const { data, error } = await service
    .from("photos")
    .select("id")
    .eq("id", photoId)
    .eq("user_id", userId)
    .is("deleted_at", null)
    .maybeSingle();
  if (error) {
    console.error("isPhotoOwnedByUser error:", error);
    return false;
  }
  return !!data;
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
