// ============================================================================
// photos-cleanup — 純関数群（deno test の対象）
// ============================================================================

export const RETENTION_DAYS = 30;
export const BATCH_SIZE = 100;
export const MAX_BATCHES = 50;

/** 保持期限のカットオフ日時（これより古い deleted_at の写真が物理削除対象）を返す。 */
export function expirationCutoff(now: Date, retentionDays: number = RETENTION_DAYS): string {
  return new Date(now.getTime() - retentionDays * 24 * 60 * 60 * 1000).toISOString();
}

export interface PhotoPathsRow {
  storage_path: string | null;
  thumbnail_path: string | null;
}

/** 1 行分の Storage 削除対象パス（原寸 + サムネ）を返す。null / 空文字は除外。 */
export function collectStoragePaths(row: PhotoPathsRow): string[] {
  return [row.storage_path, row.thumbnail_path]
    .filter((p): p is string => typeof p === "string" && p.length > 0);
}
