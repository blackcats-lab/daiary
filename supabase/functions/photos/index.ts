// ============================================================================
// photos Edge Function（雛形）
// ============================================================================
// GET    /functions/v1/photos          一覧取得
// GET    /functions/v1/photos/:id      詳細取得
// POST   /functions/v1/photos          メタデータ作成（Storage アップロードは別経路）
// PATCH  /functions/v1/photos/:id      お気に入り・タグ更新
// DELETE /functions/v1/photos/:id      論理削除
//
// Phase 1 で本実装。現状は認証 + ルーティング骨格のみ。
// 各 placeholder は同期的に 501 を返す。本実装時に async + await を付ける。
// ============================================================================

import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  const user = await authenticate(req);
  if (!user) return unauthorized();

  const url = new URL(req.url);
  // 末尾のパス: /functions/v1/photos[/<id>]
  const segments = url.pathname.split("/").filter(Boolean);
  const photoId = segments[segments.length - 1] !== "photos" ? segments[segments.length - 1] : null;

  const service = createServiceClient();

  switch (req.method) {
    case "GET":
      return photoId ? getPhoto(service, user.userId, photoId) : listPhotos(service, user.userId);
    case "POST":
      return createPhoto(service, user.userId, await req.json());
    case "PATCH":
      if (!photoId) return jsonError(400, "ID_REQUIRED", "photo id が必要です");
      return updatePhoto(service, user.userId, photoId, await req.json());
    case "DELETE":
      if (!photoId) return jsonError(400, "ID_REQUIRED", "photo id が必要です");
      return deletePhoto(service, user.userId, photoId);
    default:
      return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} は未対応です`);
  }
});

// TODO: Phase 1 で本実装する際は async + await + DB アクセスを追加すること
function listPhotos(_service: unknown, _userId: string): Response {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function getPhoto(_service: unknown, _userId: string, _id: string): Response {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function createPhoto(_service: unknown, _userId: string, _body: unknown): Response {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function updatePhoto(
  _service: unknown,
  _userId: string,
  _id: string,
  _body: unknown,
): Response {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function deletePhoto(_service: unknown, _userId: string, _id: string): Response {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
