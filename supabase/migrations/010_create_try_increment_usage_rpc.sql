-- ===========================================================================
-- 010: try_increment_usage / decrement_usage RPC
-- ===========================================================================
-- ai-generate の利用回数制御をアトミックにするための RPC。
--
-- 従来は「カウント読み取り → AI 呼び出し → increment_usage(007)」の
-- check-then-act 構成だったため、並列リクエストで上限をすり抜けられた
-- （例: 残り 1 回で N 本同時に投げると N 回とも通り、AI コストが超過分だけ発生）。
--
-- try_increment_usage は上限チェックと加算を 1 文の UPSERT で行う:
--   - 上限未満なら count を +1 し、更新後の当日カウントを返す
--   - 上限到達で加算できなかった場合は -1 を返す
-- decrement_usage は AI 呼び出し失敗時に確保済みの枠を返却する
-- （要件定義 3.3「エラー時の利用回数返却（成功時のみカウント）」に対応）。
--
-- 007 の increment_usage は本番適用済みの前提で変更せず残す（呼び出し元は撤去済み）。
-- ===========================================================================

CREATE OR REPLACE FUNCTION public.try_increment_usage(p_user_id UUID, p_limit INT)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  IF p_limit IS NULL OR p_limit < 1 THEN
    RETURN -1;
  END IF;

  INSERT INTO public.daily_usage (user_id, usage_date, count)
  VALUES (p_user_id, CURRENT_DATE, 1)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET count = public.daily_usage.count + 1
  WHERE public.daily_usage.count < p_limit
  RETURNING count INTO v_count;

  -- WHERE 条件を満たさず UPDATE されなかった場合（上限到達）は NULL のまま
  IF v_count IS NULL THEN
    RETURN -1;
  END IF;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_usage(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE public.daily_usage
  SET count = GREATEST(count - 1, 0)
  WHERE user_id = p_user_id AND usage_date = CURRENT_DATE
  RETURNING count INTO v_count;

  RETURN COALESCE(v_count, 0);
END;
$$;

-- service_role のみ実行可能にする（007 と同方針）
REVOKE ALL ON FUNCTION public.try_increment_usage(UUID, INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.try_increment_usage(UUID, INT) FROM anon;
REVOKE ALL ON FUNCTION public.try_increment_usage(UUID, INT) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.try_increment_usage(UUID, INT) TO service_role;

REVOKE ALL ON FUNCTION public.decrement_usage(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decrement_usage(UUID) FROM anon;
REVOKE ALL ON FUNCTION public.decrement_usage(UUID) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.decrement_usage(UUID) TO service_role;
