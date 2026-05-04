# dAIary — Project Deliverables

写真に、言葉を添えて。

**dAIary（ダイアリー）** は、写真で日々を記録し、AIが言葉を添えるフォトダイアリーアプリです。
Diary の中に「AI」を埋め込んだ造語で、ロゴでは d**AI**ary と表記します。

---

## ファイル一覧

### ドキュメント

#### 計画・要件

| ファイル | 内容 | バージョン |
|---|---|---|
| `dAIary_requirements.md` | 要件定義書 | v2.0 |
| `dAIary_implementation_plan.md` | 実装計画書 | v2.0 |

#### 実装ガイド（Phase 0 で追加）

| ファイル | 内容 |
|---|---|
| `setup.md` | ローカル開発環境セットアップ手順 |
| `api-spec.md` | Edge Functions API 仕様 |
| `architecture.md` | システム構成・データフロー・モジュール分割 |
| `er-diagram.md` | DB スキーマの Mermaid ER 図 |
| `prompt-design.md` | AI 生成のプロンプト・JSON Schema 設計 |
| `phase0-external-tasks.md` | Phase 0 外部タスクのチェックリスト |
| `gemini-poc-result.md` | Gemini API PoC 結果（実コスト・所要時間） |

### デザイン

| ファイル | 内容 | 形式 |
|---|---|---|
| `dAIary_brand_design.jsx` | ブランドデザインショーケース（インタラクティブ） | React JSX |
| `dAIary_brand_design.pdf` | ブランドデザインガイドライン（3ページ） | PDF |
| `dAIary_screen_layouts.jsx` | 画面レイアウトサンプル（インタラクティブ） | React JSX |
| `dAIary_screen_layouts.pdf` | 画面レイアウト（3ページ） | PDF |

---

## 各ドキュメントの概要

### dAIary_requirements.md（要件定義書）

アプリの機能要件・非機能要件を網羅的に定義したドキュメント。

- **プロジェクト概要**: プロダクトビジョン、ターゲットユーザー、対応プラットフォーム
- **機能要件**: カメラ撮影（画像前処理含む）、生成AI（ハッシュタグ・投稿文・構造化出力）、アルバム、課金（RevenueCat）、ユーザー管理
- **非機能要件**: パフォーマンス目標、セキュリティ設計（APIキー保護・RLS・コスト上限）、信頼性、拡張性
- **システムアーキテクチャ**: モノレポ構成、システム構成図（Flutter → Edge Functions → Gemini API）
- **データモデル**: 課金管理3テーブル（subscriptions / daily_usage / usage_logs）+ 写真管理3テーブル（photos / albums / album_photos）
- **外部サービス依存**: Gemini API、Supabase、RevenueCat、AdMob、Firebase
- **制約事項・リスク**: Edge Functions実行時間制限、API料金スケール、ストア審査ポリシー

### dAIary_implementation_plan.md（実装計画書）

技術設計からリリースまでの具体的な実装計画。

- **開発方針**: アジャイル（2週間スプリント）、モノレポ運用ルール、ブランチ戦略
- **技術設計**: モノレポ全体構成、Flutter（Riverpod + GoRouter）、Supabase Edge Functions、AIサービス抽象化層（モデル切替可能）、プロンプト設計、インフラ構成
- **開発スケジュール**: 全13週間（3.25ヶ月）、Phase 0〜3の6スプリント詳細
- **テスト計画**: ユニット / ウィジェット / Edge Function / E2E テスト方針
- **リリース後運用**: 監視・アラート、ロードマップ（v1.1〜v2.0）、KPI目標
- **コスト見積もり**: AI API原価（1リクエスト約0.032円）、固定費$0〜25/月
- **リスク管理**: 8項目のリスクと対策
- **チェックリスト**: 必須対応 / 推奨対応 / 将来検討事項

### dAIary_brand_design.jsx / .pdf（ブランドデザイン）

ロゴ・アイコン・カラーパレット・タイポグラフィのデザインガイドライン。

- **ロゴタイプ**: Playfair Display、AI部分をイタリック×ゴールドで強調
- **タグライン**: 「写真に、言葉を添えて。」（Noto Sans JP Light）
- **カラーパレット**: Brand Gold #C4956A / Deep Brown #2D2420 / Cream #F5EFE8 / Warm Accent #E8A87C
- **タイポグラフィ**: Playfair Display（ロゴ・見出し）+ Noto Sans JP（本文・UI）
- **アプリアイコン**: Light / Dark / Gold の3バリエーション × 各サイズ
- **使用例**: スプラッシュスクリーン（ライト/ダーク）、App Storeプレビュー、各背景色でのロゴ表示

JSX版はClaude.aiのArtifactsでインタラクティブに確認可能。PDF版は印刷・共有用の3ページ構成。

### dAIary_screen_layouts.jsx / .pdf（画面レイアウト）

全7画面のUIレイアウトサンプル。モバイルフレーム内にモックアップを表示し、デザインノートを付記。

| 画面 | 主なポイント |
|---|---|
| ログイン | クリームBG、ロゴ大配置、Google/Appleソーシャルログイン |
| ホーム（写真一覧） | 3カラムグリッド、フィルタータブ、ボトムナビ |
| カメラ撮影 | フルスクリーン黒背景、三分割グリッド、シャッターボタン |
| 写真詳細 | ダークUI、EXIF情報、AI生成ボタンをゴールドで強調 |
| AIテキスト生成 | スタイル選択チップ、生成結果カード、ハッシュタグチップ |
| アルバム一覧 | 2カラムグリッド、カバー写真+枚数、検索バー |
| 設定 | iOSスタイルグループ化リスト、プラン・テーマ・通知・ストレージ |

JSX版はClaude.aiのArtifactsでインタラクティブに確認可能。PDF版は印刷・共有用の3ページ構成。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| モバイル | Flutter（Riverpod + Go Router） |
| バックエンド | Supabase Edge Functions（Deno/TypeScript） |
| 生成AI | Gemini API（初期: 2.5 Flash-Lite、切替可能） |
| データベース | Supabase（Auth / Storage / PostgreSQL / Secrets） |
| 課金 | RevenueCat |
| 広告 | Google AdMob |

---

## 関連リンク

- Notion プロジェクト概要ページ（プロジェクト管理者に確認）
- アーキテクチャ設計書（architecture.md）
