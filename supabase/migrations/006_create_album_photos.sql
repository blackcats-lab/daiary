-- ===========================================================================
-- 006: album_photos 中間テーブル
-- ===========================================================================
-- albums と photos の多対多関係を表現する。
-- sort_order でアルバム内の並び順を保持。
-- RLS は「アルバムの所有者と写真の所有者が一致する」場合に操作許可。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.album_photos (
  album_id    UUID         NOT NULL REFERENCES public.albums(id) ON DELETE CASCADE,
  photo_id    UUID         NOT NULL REFERENCES public.photos(id) ON DELETE CASCADE,
  sort_order  INT          NOT NULL DEFAULT 0,
  added_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  PRIMARY KEY (album_id, photo_id)
);

CREATE INDEX IF NOT EXISTS idx_album_photos_album_sort
  ON public.album_photos(album_id, sort_order, added_at DESC);

CREATE INDEX IF NOT EXISTS idx_album_photos_photo
  ON public.album_photos(photo_id);

-- ===== RLS =====
ALTER TABLE public.album_photos ENABLE ROW LEVEL SECURITY;

-- 所有アルバムの中間レコードを SELECT 可
DROP POLICY IF EXISTS album_photos_select_own ON public.album_photos;
CREATE POLICY album_photos_select_own ON public.album_photos
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id AND a.user_id = auth.uid()
    )
  );

-- 公開アルバム経由の閲覧
DROP POLICY IF EXISTS album_photos_select_public ON public.album_photos;
CREATE POLICY album_photos_select_public ON public.album_photos
  FOR SELECT
  TO anon, authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id
        AND a.is_public = true
        AND a.share_token IS NOT NULL
    )
  );

-- 自分のアルバムに自分の写真を追加可
DROP POLICY IF EXISTS album_photos_insert_own ON public.album_photos;
CREATE POLICY album_photos_insert_own ON public.album_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id AND a.user_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.photos p
      WHERE p.id = album_photos.photo_id AND p.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS album_photos_update_own ON public.album_photos;
CREATE POLICY album_photos_update_own ON public.album_photos
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id AND a.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id AND a.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS album_photos_delete_own ON public.album_photos;
CREATE POLICY album_photos_delete_own ON public.album_photos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.albums a
      WHERE a.id = album_photos.album_id AND a.user_id = auth.uid()
    )
  );
