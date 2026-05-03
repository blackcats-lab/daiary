-- ===========================================================================
-- 003: usage_logs テーブル
-- ===========================================================================
-- AI 生成 1 リクエストごとの詳細ログ。コスト集計・モデル別分析に使う。
-- 書き込みは Edge Function（service_role）からのみ。
-- ユーザーは自分のログを SELECT 可（プラン画面・履歴表示用）。
-- ===========================================================================

CREATE TABLE IF NOT EXISTS public.usage_logs (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
  model          TEXT         NOT NULL,
  input_tokens   INT          NOT NULL DEFAULT 0 CHECK (input_tokens >= 0),
  output_tokens  INT          NOT NULL DEFAULT 0 CHECK (output_tokens >= 0),
  cost_usd       NUMERIC(10,6) NOT NULL DEFAULT 0 CHECK (cost_usd >= 0)
);

CREATE INDEX IF NOT EXISTS idx_usage_logs_user_created
  ON public.usage_logs(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_usage_logs_created_model
  ON public.usage_logs(created_at DESC, model);

-- ===== RLS =====
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;

-- 自分のログのみ SELECT 可
DROP POLICY IF EXISTS usage_logs_select_own ON public.usage_logs;
CREATE POLICY usage_logs_select_own ON public.usage_logs
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- INSERT は service_role のみ（明示ポリシー無し）
