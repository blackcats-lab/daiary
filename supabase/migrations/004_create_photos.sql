-- ===========================================================================
-- 004: photos テーブル
-- ===========================================================================
-- 撮影／取り込みされた写真のメタデータ。実体は Supabase Storage に保存。
-- deleted_at による論理削除をサポート（30 日後に物理削除する運用予定）。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.photos (
  id                 UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  storage_path       TEXT         NOT NULL,
  thumbnail_path     TEXT,
  original_filename  VARCHAR(255),
  file_size          BIGINT       CHECK (file_size IS NULL OR file_size >= 0),
  width              INT          CHECK (width IS NULL OR width > 0),
  height             INT          CHECK (height IS NULL OR height > 0),
  exif_data          JSONB        NOT NULL DEFAULT '{}'::jsonb,
  ai_tags            JSONB        NOT NULL DEFAULT '[]'::jsonb,
  is_favorite        BOOLEAN      NOT NULL DEFAULT false,
  deleted_at         TIMESTAMPTZ,
  created_at         TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- 一覧取得: 自分の未削除写真を新しい順
CREATE INDEX IF NOT EXISTS idx_photos_user_created
  ON public.photos(user_id, created_at DESC)
  WHERE deleted_at IS NULL;

-- お気に入りフィルタ
CREATE INDEX IF NOT EXISTS idx_photos_user_favorite
  ON public.photos(user_id, created_at DESC)
  WHERE is_favorite = true AND deleted_at IS NULL;

-- AI タグ検索（GIN）
CREATE INDEX IF NOT EXISTS idx_photos_ai_tags
  ON public.photos USING GIN (ai_tags);

-- ゴミ箱（論理削除済み）の自動削除バッチで使用
CREATE INDEX IF NOT EXISTS idx_photos_deleted_at
  ON public.photos(deleted_at)
  WHERE deleted_at IS NOT NULL;

-- ===== RLS =====
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS photos_select_own ON public.photos;
CREATE POLICY photos_select_own ON public.photos
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS photos_insert_own ON public.photos;
CREATE POLICY photos_insert_own ON public.photos
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS photos_update_own ON public.photos;
CREATE POLICY photos_update_own ON public.photos
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS photos_delete_own ON public.photos;
CREATE POLICY photos_delete_own ON public.photos
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());
