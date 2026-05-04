-- ===========================================================================
-- Seed data for local development
-- ===========================================================================
-- `supabase db reset` 実行時に migrations の後に流される。
-- 本番環境では適用されない。
--
-- 開発時にダミーユーザー・サンプル写真等を投入したい場合はここに記述する。
-- 現状は雛形のみ（コメントアウト例）。
-- ===========================================================================

-- 例: ダミーユーザーの subscriptions 行を作成
-- INSERT INTO public.subscriptions (user_id, plan, expires_at, revenuecat_id)
-- VALUES
--   ('00000000-0000-0000-0000-000000000001', 'free', NULL, NULL),
--   ('00000000-0000-0000-0000-000000000002', 'premium', now() + interval '30 days', 'rc_test_premium_001');

-- 例: ダミーアルバム
-- INSERT INTO public.albums (id, user_id, name, is_public)
-- VALUES
--   (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', 'My First Album', false);
