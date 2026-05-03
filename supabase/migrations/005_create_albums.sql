-- ===========================================================================
-- 005: albums テーブル
-- ===========================================================================
-- ユーザーが作成するアルバム。share_token を介して公開リンク共有が可能。
-- cover_photo_id は photos(id) を参照（photos が先に作成済みの前提）。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.albums (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name            VARCHAR(100) NOT NULL,
  cover_photo_id  UUID         REFERENCES public.photos(id) ON DELETE SET NULL,
  is_public       BOOLEAN      NOT NULL DEFAULT false,
  share_token     VARCHAR(64)  UNIQUE,
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_albums_user_created
  ON public.albums(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_albums_share_token
  ON public.albums(share_token)
  WHERE share_token IS NOT NULL;

-- updated_at 自動更新（001 で作成した関数を再利用）
DROP TRIGGER IF EXISTS trg_albums_set_updated_at ON public.albums;
CREATE TRIGGER trg_albums_set_updated_at
  BEFORE UPDATE ON public.albums
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ===== RLS =====
ALTER TABLE public.albums ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS albums_select_own ON public.albums;
CREATE POLICY albums_select_own ON public.albums
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 公開アルバムは share_token 経由で誰でも閲覧可（anon 含む）
DROP POLICY IF EXISTS albums_select_public ON public.albums;
CREATE POLICY albums_select_public ON public.albums
  FOR SELECT
  TO anon, authenticated
  USING (is_public = true AND share_token IS NOT NULL);

DROP POLICY IF EXISTS albums_insert_own ON public.albums;
CREATE POLICY albums_insert_own ON public.albums
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS albums_update_own ON public.albums;
CREATE POLICY albums_update_own ON public.albums
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS albums_delete_own ON public.albums;
CREATE POLICY albums_delete_own ON public.albums
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());
