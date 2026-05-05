-- ===========================================================================
-- 008: photos バケットの owner-only Storage RLS
-- ===========================================================================
-- パス命名規則: {user_id}/{photo_id}.jpg, {user_id}/thumb_{photo_id}.jpg
-- 1 段目フォルダが auth.uid() と一致するオブジェクトのみ操作可。
--
-- photos テーブル本体への INSERT は Edge Function (service_role) 経由で
-- 行うため photos テーブル RLS をバイパスするが、Storage への
-- uploadBinary は Flutter SDK から authenticated で叩くため、本ポリシーで
-- ownership を強制する。
-- ===========================================================================

DROP POLICY IF EXISTS photos_storage_select_own ON storage.objects;
CREATE POLICY photos_storage_select_own ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS photos_storage_insert_own ON storage.objects;
CREATE POLICY photos_storage_insert_own ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS photos_storage_update_own ON storage.objects;
CREATE POLICY photos_storage_update_own ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS photos_storage_delete_own ON storage.objects;
CREATE POLICY photos_storage_delete_own ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
