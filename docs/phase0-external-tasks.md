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

- [ ] [Google AI Studio](https://aistudio.google.com/) で API キー取得
- [ ] `supabase/.env.local` の `GEMINI_API_KEY` に投入してローカル `ai-generate` を叩く
  - サンプル写真 → `taskType: "hashtag"` で 10 個取得できるか
  - サンプル写真 → `taskType: "caption"` で 80〜140 字の caption が返るか
  - `usage_logs` に `input_tokens` / `output_tokens` / `cost_usd` が記録されるか
- [ ] 1 リクエストあたりのコストが想定（約 0.032 円）に収まるか確認
- [ ] PoC 結果を `docs/` 配下に PoC レポートとして残す（任意）
- [ ] 本番 Supabase Secrets に `GEMINI_API_KEY` を投入

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

- [ ] `develop` ブランチを作成
- [ ] Branch protection rule:
  - `main` / `develop` への直 push 禁止
  - PR には CI（`mobile-ci` / `functions-ci` / `db-migration` のうち該当するもの）通過を必須化
  - Required reviewers 1 名以上
- [ ] GitHub Issues / Projects でスプリントボード作成
- [ ] Discord 連携 Webhook（任意）

## 7. ストア準備（Phase 3 で必要）

- [ ] Apple Developer Program 加入（年 $99）
- [ ] Google Play Developer Console 加入（一括 $25）
- [ ] アプリ名「dAIary」の利用可否確認・確保
- [ ] Bundle ID / Application ID を決定し、Flutter プロジェクトに反映
- [ ] App Store / Play Store のアプリ情報・スクリーンショット枠を確保

## 8. 監視・分析（任意・Phase 3 までに整備）

- [ ] Sentry プロジェクト作成、DSN を `mobile/.env` に追加
- [ ] Firebase Cloud Messaging プロジェクト作成（プッシュ通知用）
- [ ] Supabase Logs / Postgres Stats のダッシュボード確認運用
