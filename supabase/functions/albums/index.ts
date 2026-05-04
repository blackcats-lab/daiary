// ============================================================================
// albums Edge Function（雛形）
// ============================================================================
// GET    /functions/v1/albums          一覧取得
// GET    /functions/v1/albums/:id      詳細取得（写真リスト含む）
// POST   /functions/v1/albums          作成
// PATCH  /functions/v1/albums/:id      編集（名前・カバー写真・公開設定）
// DELETE /functions/v1/albums/:id      削除
//
// Phase 1（Sprint 3）で本実装。現状は認証 + ルーティング骨格のみ。
// ============================================================================

import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  const user = await authenticate(req);
  if (!user) return unauthorized();

  const url = new URL(req.url);
  const segments = url.pathname.split("/").filter(Boolean);
  const albumId = segments[segments.length - 1] !== "albums" ? segments[segments.length - 1] : null;

  const service = createServiceClient();

  switch (req.method) {
    case "GET":
      return albumId
        ? await getAlbum(service, user.userId, albumId)
        : await listAlbums(service, user.userId);
    case "POST":
      return await createAlbum(service, user.userId, await req.json());
    case "PATCH":
      if (!albumId) return jsonError(400, "ID_REQUIRED", "album id が必要です");
      return await updateAlbum(service, user.userId, albumId, await req.json());
    case "DELETE":
      if (!albumId) return jsonError(400, "ID_REQUIRED", "album id が必要です");
      return await deleteAlbum(service, user.userId, albumId);
    default:
      return jsonError(405, "METHOD_NOT_ALLOWED", `${req.method} は未対応です`);
  }
});

// deno-lint-ignore no-unused-vars
async function listAlbums(_service: unknown, _userId: string): Promise<Response> {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

// deno-lint-ignore no-unused-vars
async function getAlbum(_service: unknown, _userId: string, _id: string): Promise<Response> {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

// deno-lint-ignore no-unused-vars
async function createAlbum(_service: unknown, _userId: string, _body: unknown): Promise<Response> {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

// deno-lint-ignore no-unused-vars
async function updateAlbum(
  _service: unknown,
  _userId: string,
  _id: string,
  _body: unknown,
): Promise<Response> {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

// deno-lint-ignore no-unused-vars
async function deleteAlbum(_service: unknown, _userId: string, _id: string): Promise<Response> {
  return jsonError(501, "NOT_IMPLEMENTED", "Phase 1 で実装予定");
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
