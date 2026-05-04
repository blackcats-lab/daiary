-- ===========================================================================
-- 007: increment_usage RPC
-- ===========================================================================
-- AI 生成成功時に Edge Function（service_role）から呼ばれる。
-- daily_usage(user_id, today) を UPSERT し、count を +1 した最新値を返す。
-- 競合時は ON CONFLICT で安全にインクリメント。
--
-- 戻り値: 当日の利用回数（更新後）
-- 利用例: SELECT public.increment_usage('00000000-...');
-- ===========================================================================

CREATE OR REPLACE FUNCTION public.increment_usage(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  INSERT INTO public.daily_usage (user_id, usage_date, count)
  VALUES (p_user_id, CURRENT_DATE, 1)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET count = public.daily_usage.count + 1
  RETURNING count INTO v_count;

  RETURN v_count;
END;
$$;

-- service_role のみ実行可能にする
REVOKE ALL ON FUNCTION public.increment_usage(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.increment_usage(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.increment_usage(UUID) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.increment_usage(UUID) TO service_role;
