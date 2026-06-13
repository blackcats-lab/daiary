# Phase 0 外部タスク（コード生成では完結しないもの）

Claude Code が直接実行できないが、Phase 0 完了に必要な作業。
Phase 1 開発開始前に消化しておくこと。

## 1. UI/UX デザイン（Figma）

- [ ] Figma プロジェクト作成
- [ ] [docs/dAIary_brand_design.jsx](dAIary_brand_design.jsx) と [docs/dAIary_screen_layouts.jsx](dAIary_screen_layouts.jsx) のデザイントークン・レイアウトを Figma に展開
- [ ] 7 画面（ログイン / ホーム / カメラ / 写真詳細 / AI 生成 / アルバム / 設定）のワイヤーフレーム + モックアップ
- [ ] アプリアイコン 3 バリエーション × 各サイズ（1024 / 180 / 120 / 58 px）の書き出し
- [ ] スプラッシュスクリーン書き出し
- [ ] チームに共有 URL を周知

## 2. Supabase 本番プロジェクト

- [ ] <https://supabase.com> でプロジェクト作成（リージョン: ap-northeast-1 推奨）
- [ ] `supabase login` → `supabase link --project-ref <ref>` で連携
- [ ] `make db-push` でマイグレーション 001-007 を本番に適用
- [ ] Storage バケット `photos` を作成（public 不可）
- [ ] Auth プロバイダ設定: Google / Apple OAuth クライアント登録
- [ ] Secrets 登録: `GEMINI_API_KEY`, `REVENUECAT_WEBHOOK_AUTH`, `AI_PROVIDER`, `AI_MODEL`
- [ ] `supabase functions deploy` で Edge Functions をデプロイ

## 3. Gemini API（PoC・本番）

- [x] [Google AI Studio](https://aistudio.google.com/) で API キー取得
- [x] `supabase/functions/.env.local` の `GEMINI_API_KEY` に投入してローカル `ai-generate` を叩く
  - サンプル写真 → `taskType: "hashtag"` で 10 個取得できるか → ✅ 8 個取得（指定数で動作）
  - サンプル写真 → `taskType: "caption"` で 80〜140 字の caption が返るか → ✅ caption + altText 取得
  - `usage_logs` に `input_tokens` / `output_tokens` / `cost_usd` が記録されるか → ✅
- [x] 1 リクエストあたりのコストが想定（約 0.032 円）に収まるか確認 → ✅ 実測 0.008〜0.014 円（想定より安い）
- [x] PoC 結果を `docs/` 配下に PoC レポートとして残す → [gemini-poc-result.md](gemini-poc-result.md)
- [ ] 本番 Supabase Secrets に `GEMINI_API_KEY` を投入（§2 と合わせて実施）

## 4. RevenueCat

- [ ] RevenueCat アカウント作成 → アプリ追加
- [ ] App Store Connect / Google Play Console で App / In-App 購入プロダクト登録
- [ ] RevenueCat 側でプロダクト・Entitlement を構成
- [ ] Webhook URL を `${SUPABASE_URL}/functions/v1/revenuecat-webhook` に設定
- [ ] Webhook Authorization の固定値を発行し、Supabase Secrets `REVENUECAT_WEBHOOK_AUTH` に登録
- [ ] テスト購入で `subscriptions` テーブルが正しく upsert されるか確認

## 5. AdMob（Phase 2 で必要）

- [ ] AdMob アカウント作成 → アプリ登録（iOS / Android）
- [ ] 広告ユニット ID 発行（バナー / インタースティシャル / リワード）
- [ ] `mobile/.env` に AdMob ID を追加（後続スプリント）

## 6. GitHub リポジトリ運用

- [x] `develop` ブランチを作成
- [x] Branch protection rule:
  - `main` / `develop` で PR 必須
  - Required status checks: `Analyze & Test`, `Lint & Test`, `Validate migrations on local Supabase`
  - 必要に応じて Required reviewers を 1 名以上に
- [ ] GitHub Issues / Projects でスプリントボード作成
- [ ] Discord 連携 Webhook（任意）

> Required status check の登録は「過去 7 日に走った check 名」をサジェストする UI のため、
> 初回は PR を 1 つ作って CI を完走させてから登録する必要がある（dAIary では PR #1 で対応済み）。

## 7. ストア準備（Phase 3 で必要）

- [ ] Apple Developer Program 加入（年 $99）
- [ ] Google Play Developer Console 加入（一括 $25）
- [ ] アプリ名「dAIary」の利用可否確認・確保
- [ ] Bundle ID / Application ID を決定し、Flutter プロジェクトに反映
- [ ] App Store / Play Store のアプリ情報・スクリーンショット枠を確保

## 9. ゴミ箱自動削除バッチ（Sprint 3）

論理削除から 30 日経過した写真を物理削除する `photos-cleanup` Edge Function を
GitHub Actions の日次スケジュールから叩く（`.github/workflows/photos-cleanup.yml`）。

- [ ] GitHub repo Secrets に `SUPABASE_URL` を登録（本番 Supabase プロジェクトの URL）
- [ ] GitHub repo Secrets に `SUPABASE_SERVICE_ROLE_KEY` を登録（`sb_secret_...`。**チャットに貼らない**）
- [ ] `supabase functions deploy photos-cleanup` で本番にデプロイ
- [ ] Actions の `photos-cleanup` を `workflow_dispatch` で手動実行し、`{ "deleted": N }` が返るか確認

> Secrets 未登録の状態では workflow は明示的に fail する（誤って無認証で叩かないため）。

## 8. 監視・分析（任意・Phase 3 までに整備）

- [ ] Sentry プロジェクト作成、DSN を `mobile/.env` に追加
- [ ] Firebase Cloud Messaging プロジェクト作成（プッシュ通知用）
- [ ] Supabase Logs / Postgres Stats のダッシュボード確認運用
