-- ===========================================================================
-- 011: 公開アルバムの anon SELECT ポリシーを撤去
-- ===========================================================================
-- 005 の albums_select_public / 006 の album_photos_select_public は
-- 「is_public = true AND share_token IS NOT NULL」という行フィルタのみで、
-- トークンの照合を行わない。そのため anon キーだけで
--   GET /rest/v1/albums?is_public=eq.true&select=id,name,user_id,share_token
-- のように全ユーザーの公開アルバムを列挙でき、共有リンクの秘密であるはずの
-- share_token 自体と所有者の user_id まで収集できてしまう。
--
-- 共有リンク閲覧機能（v1.1 予定）は未実装であり、現状このポリシーは
-- リークにしか働かないため撤去する。v1.1 では「トークン完全一致を要求する
-- SECURITY DEFINER RPC もしくは Edge Function」経由で公開閲覧を実装すること
-- （オープンな RLS ポリシーでは実現しない）。
--
-- 既存マイグレーション（005/006）は本番適用済みの前提で変更しない。
-- ===========================================================================

DROP POLICY IF EXISTS albums_select_public ON public.albums;
DROP POLICY IF EXISTS album_photos_select_public ON public.album_photos;
