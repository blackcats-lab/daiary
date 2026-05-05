-- ===========================================================================
-- 009: photos に caption / alt_text を追加（Sprint 2 #9）
-- ===========================================================================
-- AI 生成の投稿文（caption）と代替テキスト（alt_text）を写真メタデータに保存。
-- caption は 80〜140 字程度を想定（prompt-design.md）が、稀に LLM が超過する
-- ケースに備えて 500 字を上限とする保険的な CHECK 制約を付与。
-- alt_text は視覚障害者向け代替テキストで、短めの記述を想定し 300 字上限。
-- 検索インデックスは v1 では caption ベース検索を行わないため追加しない。
-- ===========================================================================

ALTER TABLE public.photos
  ADD COLUMN IF NOT EXISTS caption  TEXT,
  ADD COLUMN IF NOT EXISTS alt_text TEXT;

ALTER TABLE public.photos
  DROP CONSTRAINT IF EXISTS photos_caption_length_chk;
ALTER TABLE public.photos
  ADD CONSTRAINT photos_caption_length_chk
    CHECK (caption IS NULL OR char_length(caption) <= 500);

ALTER TABLE public.photos
  DROP CONSTRAINT IF EXISTS photos_alt_text_length_chk;
ALTER TABLE public.photos
  ADD CONSTRAINT photos_alt_text_length_chk
    CHECK (alt_text IS NULL OR char_length(alt_text) <= 300);
