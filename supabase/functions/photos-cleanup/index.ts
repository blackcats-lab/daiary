// ============================================================================
// photos-cleanup Edge Function
// ============================================================================
// POST /functions/v1/photos-cleanup
// 論理削除から 30 日経過した写真を物理削除するバッチ。
// GitHub Actions の日次スケジュール（.github/workflows/photos-cleanup.yml）から呼ばれる。
//
// 認証: `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>` の完全一致のみ許可。
// ユーザー JWT では呼び出せない（config.toml で verify_jwt = false にしている）。
//
// 削除順序は Storage（原寸 + サムネ）→ DB 行。Storage 削除に失敗した写真は
// スキップして行を残し、次回実行時に再試行する。
// ============================================================================

import { createServiceClient } from "../_shared/auth.ts";
import { BATCH_SIZE, collectStoragePaths, expirationCutoff, MAX_BATCHES } from "./cleanup.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonError(405, "METHOD_NOT_ALLOWED", "POST のみ受け付けます");
  }

  const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!expected) {
    console.error("SUPABASE_SERVICE_ROLE_KEY 未設定");
    return jsonError(500, "CONFIG_ERROR", "サーバ設定が不完全です");
  }
  if (req.headers.get("Authorization") !== `Bearer ${expected}`) {
    return jsonError(401, "UNAUTHORIZED", "認証に失敗しました");
  }

  const service = createServiceClient();
  const cutoff = expirationCutoff(new Date());

  let deleted = 0;
  let skipped = 0;

  try {
    for (let batch = 0; batch < MAX_BATCHES; batch++) {
      // deleted_at < cutoff は NULL（未削除）を含まない
      const { data, error } = await service
        .from("photos")
        .select("id, storage_path, thumbnail_path")
        .lt("deleted_at", cutoff)
        .order("deleted_at", { ascending: true })
        .limit(BATCH_SIZE);

      if (error) {
        console.error("photos-cleanup select error:", error);
        return jsonError(500, "DB_ERROR", "削除対象の取得に失敗しました");
      }

      const rows = data ?? [];
      if (rows.length === 0) break;

      let deletedInBatch = 0;
      for (const row of rows) {
        const paths = collectStoragePaths(row);
        if (paths.length > 0) {
          const { error: storageError } = await service.storage.from("photos").remove(paths);
          if (storageError) {
            console.error(`photos-cleanup storage error (photo ${row.id}):`, storageError);
            skipped++;
            continue;
          }
        }

        const { error: deleteError } = await service.from("photos").delete().eq("id", row.id);
        if (deleteError) {
          console.error(`photos-cleanup delete error (photo ${row.id}):`, deleteError);
          skipped++;
          continue;
        }

        deleted++;
        deletedInBatch++;
      }

      // バッチ内で 1 件も消せなかった場合は同じ行を再取得し続けるため打ち切る
      if (deletedInBatch === 0 || rows.length < BATCH_SIZE) break;
    }
  } catch (e) {
    console.error("photos-cleanup handler error:", e);
    return jsonError(500, "INTERNAL_ERROR", "サーバ内部エラー");
  }

  console.log(`photos-cleanup done: deleted=${deleted} skipped=${skipped} cutoff=${cutoff}`);
  return new Response(
    JSON.stringify({ deleted, skipped, cutoff }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
