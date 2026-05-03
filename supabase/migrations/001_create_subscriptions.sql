-- ===========================================================================
-- 001: subscriptions テーブル
-- ===========================================================================
-- ユーザーごとのサブスク状態を保持する 1:1 テーブル。
-- 書き込みは Edge Function（service_role）からのみ行い、
-- ユーザー（authenticated）は自分の行を読むことのみ許可する。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
  user_id        UUID         PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  plan           TEXT         NOT NULL DEFAULT 'free' CHECK (plan IN ('free', 'premium')),
  expires_at     TIMESTAMPTZ,
  revenuecat_id  TEXT,
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_revenuecat_id
  ON public.subscriptions(revenuecat_id)
  WHERE revenuecat_id IS NOT NULL;

-- updated_at 自動更新トリガー
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_subscriptions_set_updated_at ON public.subscriptions;
CREATE TRIGGER trg_subscriptions_set_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ===== RLS =====
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- 自分の行のみ SELECT 可
DROP POLICY IF EXISTS subscriptions_select_own ON public.subscriptions;
CREATE POLICY subscriptions_select_own ON public.subscriptions
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- INSERT / UPDATE / DELETE は service_role のみ（明示ポリシー無し → authenticated には不可）
