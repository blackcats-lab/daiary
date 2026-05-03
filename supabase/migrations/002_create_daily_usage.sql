-- ===========================================================================
-- 002: daily_usage テーブル
-- ===========================================================================
-- ユーザーの 1 日あたりの AI 生成利用回数を記録する。
-- PK: (user_id, usage_date) でアトミック UPSERT を可能にする。
-- 書き込みは increment_usage() RPC（007）経由のみ。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.daily_usage (
  user_id     UUID  NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date  DATE  NOT NULL,
  count       INT   NOT NULL DEFAULT 0 CHECK (count >= 0),
  PRIMARY KEY (user_id, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date
  ON public.daily_usage(user_id, usage_date DESC);

-- ===== RLS =====
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;

-- 自分の行のみ SELECT 可（残回数表示用）
DROP POLICY IF EXISTS daily_usage_select_own ON public.daily_usage;
CREATE POLICY daily_usage_select_own ON public.daily_usage
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- INSERT / UPDATE は service_role のみ（増分は RPC 経由）
