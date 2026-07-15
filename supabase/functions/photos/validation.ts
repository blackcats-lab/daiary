// ============================================================================
// photos Edge Function — ルーティング解決・入力検証の純関数群
// ============================================================================
// Supabase クライアントに依存しない純関数のみを置く（deno test の対象）。
// ============================================================================

export const DEFAULT_LIMIT = 50;
export const MAX_LIMIT = 100;
export const MAX_CAPTION_LENGTH = 500;
export const MAX_ALT_TEXT_LENGTH = 300;
export const MAX_TAG_COUNT = 30;
export const MAX_TAG_LENGTH = 50;

export type PhotosRoute =
  | { kind: "collection" }
  | { kind: "tags" }
  | { kind: "photo"; id: string }
  | { kind: "restore"; id: string }
  | { kind: "unknown" };

// パス例: /functions/v1/photos, /photos/:id, /photos/tags, /photos/:id/restore
export function resolvePhotosRoute(pathname: string): PhotosRoute {
  const segments = pathname.split("/").filter(Boolean);
  const idx = segments.lastIndexOf("photos");
  if (idx === -1) return { kind: "unknown" };

  const rest = segments.slice(idx + 1);
  if (rest.length === 0) return { kind: "collection" };
  if (rest.length === 1) {
    return rest[0] === "tags" ? { kind: "tags" } : { kind: "photo", id: rest[0] };
  }
  if (rest.length === 2 && rest[1] === "restore") return { kind: "restore", id: rest[0] };
  return { kind: "unknown" };
}

// タグ検索は保存値そのままの完全一致（AI 生成タグは "#" 付きで保存されている）。
// trim のみ行い、"#" の付け外しはしない。
export function normalizeTagQuery(raw: string | null): string | null {
  const tag = raw?.trim() ?? "";
  return tag ? tag : null;
}

export function clampLimit(value: number): number {
  if (!Number.isFinite(value) || value <= 0) return DEFAULT_LIMIT;
  return Math.min(Math.floor(value), MAX_LIMIT);
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export function isUuid(s: string): boolean {
  return UUID_RE.test(s);
}

export function captionError(caption: string): string | null {
  if (caption.length > MAX_CAPTION_LENGTH) {
    return `caption は ${MAX_CAPTION_LENGTH} 文字以内で指定してください`;
  }
  return null;
}

export function altTextError(altText: string): string | null {
  if (altText.length > MAX_ALT_TEXT_LENGTH) {
    return `alt_text は ${MAX_ALT_TEXT_LENGTH} 文字以内で指定してください`;
  }
  return null;
}

export function aiTagsError(tags: unknown[]): string | null {
  if (tags.length > MAX_TAG_COUNT) {
    return `ai_tags は最大 ${MAX_TAG_COUNT} 件までです`;
  }
  for (const tag of tags) {
    if (typeof tag !== "string" || tag.trim().length === 0) {
      return "ai_tags の要素は空でない文字列で指定してください";
    }
    if (tag.length > MAX_TAG_LENGTH) {
      return `ai_tags の各要素は ${MAX_TAG_LENGTH} 文字以内で指定してください`;
    }
  }
  return null;
}

export function positiveIntError(name: string, value: unknown): string | null {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    return `${name} は正の整数で指定してください`;
  }
  return null;
}

export const MAX_STORAGE_PATH_LENGTH = 1024;

// Storage パスは本人のフォルダ（{userId}/...）配下のみ許可する。
// 他ユーザーのパスを登録できると、物理削除・cleanup（service_role で Storage RLS を
// バイパスする）経由で他人の実ファイルを消せてしまう。
export function storagePathError(field: string, value: unknown, userId: string): string | null {
  if (typeof value !== "string" || value.length === 0) {
    return `${field} は空でない文字列で指定してください`;
  }
  if (value.length > MAX_STORAGE_PATH_LENGTH) {
    return `${field} は ${MAX_STORAGE_PATH_LENGTH} 文字以内で指定してください`;
  }
  if (value.includes("..") || value.includes("//") || value.includes("\\")) {
    return `${field} に不正なパスが含まれます`;
  }
  if (!value.startsWith(`${userId}/`)) {
    return `${field} は自分のフォルダ配下のパスのみ指定できます`;
  }
  return null;
}
