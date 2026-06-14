# dAIary（ダイアリー） 実装計画書

**バージョン:** 2.0  
**作成日:** 2026年5月3日  
**ステータス:** ドラフト

---

## 1. 開発体制・方針

### 1.1 開発方針

- アジャイル開発（2週間スプリント）
- MVP（Minimum Viable Product）を最短でリリースし、ユーザーフィードバックに基づいて改善
- バックエンドはSupabase Edge Functions（Deno/TypeScript）に統一し、追加インフラを排除
- AIモデルはサービス層で抽象化し、設定変更のみで切替可能な設計
- モノレポ構成を採用し、モバイル・Supabase設定・ドキュメントを単一リポジトリで管理

### 1.2 開発環境

| 項目 | ツール |
|---|---|
| バージョン管理 | GitHub（モノレポ） |
| CI/CD | GitHub Actions（パス指定による差分ビルド） |
| プロジェクト管理 | GitHub Issues + Projects |
| デザイン | Figma |
| API仕様 | Edge Functions の型定義 + docs/ に仕様書 |
| コミュニケーション | Discord |
| タスクランナー | Makefile（ルートから各パッケージの操作を統一） |
| ローカル開発 | Supabase CLI（supabase start）|

### 1.3 ブランチ戦略

```
main ─── develop ─── feature/xxx
              │
              ├──── feature/mobile/cam-001-camera
              ├──── feature/functions/ai-001-generate
              ├──── feature/mobile/alb-001-album
              ├──── feature/infra/ci-setup
              └──── release/v1.0.0
```

- `main`: 本番リリース用
- `develop`: 開発統合ブランチ
- `feature/mobile/*`: モバイル機能開発ブランチ
- `feature/functions/*`: Edge Functions開発ブランチ
- `feature/infra/*`: インフラ・CI/CD関連ブランチ
- `release/*`: リリース候補ブランチ
- `hotfix/*`: 緊急修正用ブランチ

### 1.4 モノレポ運用ルール

- CI/CDはパスフィルタにより変更のあったパッケージのみビルド・テストを実行
  - `mobile/` 配下の変更 → Flutter lint / test / build
  - `supabase/functions/` 配下の変更 → Deno lint / test / deploy
  - `supabase/migrations/` 配下の変更 → マイグレーション検証
- ルートの `Makefile` から各パッケージの主要操作を統一実行可能
- 共有ドキュメント（API仕様・設計資料）は `docs/` に集約
- 環境変数テンプレートは各パッケージの `.env.example` で管理

---

## 2. 技術設計

### 2.1 モノレポ全体構成

```
daiary/                               # リポジトリルート
├── README.md
├── Makefile                          # 統一タスクランナー
├── .github/
│   └── workflows/
│       ├── mobile-ci.yml             # Flutter CI（mobile/変更時のみ）
│       ├── functions-ci.yml          # Edge Functions CI
│       └── db-migration.yml          # マイグレーション検証
├── mobile/                           # Flutter アプリ
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── .env.example
│   ├── lib/
│   ├── test/
│   ├── integration_test/
│   └── android/ & ios/
├── supabase/                         # Supabase設定
│   ├── config.toml
│   ├── functions/                    # Edge Functions
│   │   ├── ai-generate/             # AI生成エンドポイント
│   │   │   └── index.ts
│   │   ├── revenuecat-webhook/       # RevenueCat Webhook受信
│   │   │   └── index.ts
│   │   ├── photos/                   # 写真管理
│   │   │   └── index.ts
│   │   ├── albums/                   # アルバム管理
│   │   │   └── index.ts
│   │   └── _shared/                  # 共通モジュール
│   │       ├── ai-service.ts         # AIモデル抽象化層
│   │       ├── auth.ts               # 認証ヘルパー
│   │       ├── usage.ts              # 利用回数管理
│   │       └── types.ts              # 共通型定義
│   ├── migrations/
│   │   ├── 001_create_subscriptions.sql
│   │   ├── 002_create_daily_usage.sql
│   │   ├── 003_create_usage_logs.sql
│   │   ├── 004_create_photos.sql
│   │   ├── 005_create_albums.sql
│   │   ├── 006_create_album_photos.sql
│   │   └── 007_create_increment_usage_rpc.sql
│   └── seed.sql                      # 開発用シードデータ
├── docs/                             # 共有ドキュメント
│   ├── api-spec.md
│   ├── architecture.md
│   ├── er-diagram.md
│   └── prompt-design.md
└── docker-compose.yml                # ローカル開発用（Supabase Local）
```

### 2.2 Flutter（mobile/）

#### アーキテクチャ: Riverpod + Go Router + Repository Pattern

```
mobile/lib/
├── main.dart
├── app.dart
├── config/
│   ├── env.dart              # 環境変数
│   ├── theme.dart            # テーマ定義
│   └── router.dart           # GoRouter設定
├── core/
│   ├── constants/
│   ├── exceptions/
│   ├── extensions/
│   ├── utils/
│   │   └── image_preprocessor.dart  # 画像前処理
│   └── widgets/              # 共通ウィジェット
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/  # Supabase Auth
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/ # abstract
│   │   └── presentation/
│   │       ├── providers/    # Riverpod providers
│   │       ├── screens/
│   │       └── widgets/
│   ├── camera/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── ai_generate/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── album/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── data/
│       ├── domain/
│       └── presentation/
└── services/
    ├── supabase_service.dart     # Supabase統合（Auth + Edge Functions呼び出し）
    ├── admob_service.dart
    ├── purchase_service.dart      # RevenueCat SDK
    └── share_service.dart         # OS共有シート連携
```

#### 主要パッケージ

| パッケージ | 用途 |
|---|---|
| flutter_riverpod | 状態管理 |
| go_router | ルーティング |
| camera | カメラ制御 |
| image_picker | フォトライブラリ取り込み |
| flutter_image_compress | 画像前処理（リサイズ・圧縮・HEIC変換） |
| image_cropper | トリミング |
| photo_manager | 写真管理 |
| supabase_flutter | Supabase SDK（Auth + Edge Functions呼び出し） |
| google_mobile_ads | AdMob |
| purchases_flutter | RevenueCat SDK |
| flutter_secure_storage | トークン安全保管 |
| freezed / json_serializable | モデル生成 |
| cached_network_image | 画像キャッシュ |
| share_plus | OS標準共有シート |

### 2.3 Supabase Edge Functions

#### AIサービス抽象化層（_shared/ai-service.ts）

モデル切替を柔軟に行うため、AIモデル呼び出しをサービス層で抽象化する。

```typescript
// ai-service.ts の設計方針
interface AIModelConfig {
  provider: "gemini" | "openai" | "anthropic";
  model: string;
  apiKeySecret: string;    // Supabase Secrets のキー名
  endpoint: string;
}

interface GenerateRequest {
  image: string;           // base64 encoded
  prompt: string;
  responseSchema: object;  // JSON Schema
}

interface GenerateResponse {
  result: object;
  model: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
}

// 設定でモデルを切替可能
const MODEL_CONFIG: AIModelConfig = {
  provider: "gemini",
  model: "gemini-2.5-flash-lite",
  apiKeySecret: "GEMINI_API_KEY",
  endpoint: "https://generativelanguage.googleapis.com/v1beta",
};
```

#### Edge Function一覧

| 関数名 | 用途 | メソッド |
|---|---|---|
| ai-generate | ハッシュタグ・投稿文生成 | POST |
| revenuecat-webhook | RevenueCatからのサブスク状態同期 | POST |
| photos | 写真CRUD | GET / POST / PATCH / DELETE |
| albums | アルバムCRUD | GET / POST / PATCH / DELETE |

#### リクエストフロー（AI生成）

```
1. ユーザーが撮影 → スタイル選択 → 送信ボタン

2. Flutter:
   - 画像をリサイズ・圧縮（長辺1024px、JPEG80%）
   - Supabase Edge Function を呼び出し（JWT自動付与）

3. Edge Function (ai-generate):
   - JWTからuser_id取得
   - リクエストサイズ確認（≤2MB）
   - subscriptionsからplan取得
   - daily_usageから本日の利用回数取得
   - 制限超過なら429を返却
   - AIサービス層経由でモデル呼び出し
     （画像＋プロンプト＋JSON Schema を送信）

4. AIモデル（初期: Gemini 2.5 Flash-Lite）:
   - 構造化レスポンス（JSON）を返却

5. Edge Function:
   - increment_usage RPC でカウンタ+1（成功時のみ）
   - usage_logsに記録（モデル名・トークン数・コスト）
   - レスポンスをFlutterに返却

6. Flutter:
   - 結果を画面表示（ハッシュタグ / 投稿文）
```

#### サブスク状態同期フロー

```
1. ユーザーがアプリ内課金（Apple/Google）

2. Apple/Google → RevenueCat に通知

3. RevenueCat → Supabase Edge Function（revenuecat-webhook）

4. Edge Function:
   - イベントを検証
   - subscriptionsテーブルのplanとexpires_atを更新
```

### 2.4 AI生成 プロンプト設計方針

#### ハッシュタグ生成

```typescript
// Edge Function内
const response = await aiService.generate({
  image: base64Image,
  prompt: `あなたはSNSマーケティングの専門家です。
写真を分析し、エンゲージメントを最大化するハッシュタグを${count}個生成してください。
言語: ${language}、用途: ${usage}`,
  responseSchema: {
    type: "object",
    properties: {
      hashtags: {
        type: "array",
        items: { type: "string" }
      }
    },
    required: ["hashtags"]
  }
});
```

#### 投稿文生成

```typescript
const response = await aiService.generate({
  image: base64Image,
  prompt: `あなたはSNSコンテンツクリエイターです。
写真に合う${style}スタイルの投稿文を生成してください。
言語: ${language}、文章長: ${length}`,
  responseSchema: {
    type: "object",
    properties: {
      caption: { type: "string" }
    },
    required: ["caption"]
  }
});
```

構造化出力（response_schema）により不要な前置き文を排除し、出力トークンを最小化。

### 2.5 インフラ構成

```
┌─ Supabase Cloud ────────────────────────┐
│  ├── Auth (認証・JWT発行)               │
│  ├── Edge Functions (Deno/TypeScript)   │
│  │   ├── ai-generate                   │
│  │   ├── revenuecat-webhook            │
│  │   ├── photos                        │
│  │   └── albums                        │
│  ├── PostgreSQL (データベース・RLS)      │
│  ├── Storage (写真ストレージ)           │
│  └── Secrets (APIキー管理)             │
└─────────────────────────────────────────┘
         │
         ▼
┌─ 外部サービス ──────────────────────────┐
│  ├── Gemini API（初期。設定で切替可能） │
│  ├── RevenueCat (サブスク管理)          │
│  └── Firebase (FCM / Analytics)         │
└─────────────────────────────────────────┘
```

追加インフラ（Railway, Redis等）は不要。Supabaseに全て統合。

---

## 3. 開発フェーズ・スケジュール

### 3.1 フェーズ概要

| フェーズ | 期間 | 内容 |
|---|---|---|
| Phase 0: 設計・準備 | 2週間 | 環境構築、UI設計、DB設計、Gemini PoC |
| Phase 1: MVP開発 | 6週間 | コア機能の実装 |
| Phase 2: 課金・広告 | 2週間 | RevenueCat統合・AdMob |
| Phase 3: テスト・リリース準備 | 3週間 | QA・ストア申請 |
| 合計 | 約13週間（3.25ヶ月） | |

### 3.2 Phase 0: 設計・準備（2週間）

**Sprint 0（Week 1-2）**

| タスク | 詳細 | 成果物 |
|---|---|---|
| モノレポ初期セットアップ | リポジトリ作成、ディレクトリ構成、Makefile | リポジトリルート構成 |
| Supabaseプロジェクト作成 | Supabase CLI設定、ローカル環境構築 | supabase/ 設定 |
| 開発環境セットアップ | Flutter / Supabase Local の初期設定 | mobile/ + supabase/ |
| CI/CDパイプライン構築 | GitHub Actions設定（パスフィルタによる差分ビルド） | .github/workflows/ |
| UI/UXデザイン | Figmaでワイヤーフレーム・モックアップ作成 | Figmaデザインファイル |
| DBスキーマ設計 | テーブル定義・RLSポリシー・RPC関数 | supabase/migrations/ |
| API設計 | Edge Functions仕様・リクエスト/レスポンス定義 | docs/api-spec.md |
| Gemini API検証 | 画像解析・構造化出力のPoC | 検証レポート |
| AIサービス抽象化層設計 | モデル切替可能なインターフェース設計 | _shared/ai-service.ts |

### 3.3 Phase 1: MVP開発（6週間）

**Sprint 1（Week 3-4）: 認証 + カメラ基盤**

| タスク | 優先度 | 詳細 |
|---|---|---|
| Supabase Auth統合 | 高 | メール/Google/Apple認証 |
| ログイン/サインアップ画面 | 高 | Flutter UI実装 |
| カメラ撮影機能 | 高 | camera パッケージ統合 |
| フォトライブラリ取り込み | 高 | image_picker統合 |
| 画像前処理 | 高 | flutter_image_compress（リサイズ・圧縮・HEIC変換） |
| 写真のSupabase Storage保存 | 高 | アップロード処理・サムネイル生成 |
| photos Edge Function | 高 | 写真CRUD |

**Sprint 2（Week 5-6）: AI生成機能**

| タスク | 優先度 | 詳細 |
|---|---|---|
| AIサービス抽象化層実装 | 高 | _shared/ai-service.ts（モデル切替可能） |
| ai-generate Edge Function | 高 | JWT検証→利用回数チェック→AI呼び出し→ログ記録 |
| ハッシュタグ生成機能 | 高 | 画像＋プロンプト→構造化出力 |
| 投稿文生成機能 | 高 | スタイル指定→構造化出力 |
| AI生成UI | 高 | スタイル選択・結果表示・編集画面 |
| クリップボードコピー・共有機能 | 高 | share_plus統合 |
| 利用回数制限・increment_usage RPC | 中 | アトミックカウンタ・成功時のみ加算 |
| usage_logs記録 | 中 | モデル名・トークン数・コストを記録 |

**Sprint 3（Week 7-8）: アルバム + 写真管理**

| タスク | 優先度 | 状態 | 詳細 |
|---|---|---|---|
| albums Edge Function | 高 | ✅ | アルバムCRUD（PR #19） |
| アルバム管理UI | 高 | ✅ | 作成・編集・削除・写真追加（PR #22-#23） |
| 写真一覧・詳細画面 | 高 | ✅ | グリッドビュー・EXIF表示（PR #20） |
| 写真編集機能 | 中 | ✅ | トリミング・回転・明るさ/コントラスト/彩度・フィルタ11種（PR #29） |
| お気に入り・検索機能 | 中 | ✅ | AIタグベース検索（完全一致）・お気に入りフィルタ（PR #26） |
| クラウド同期 | 中 | ✅ | 撮影→Storageアップロード（Sprint 1 #6）+ owner-only RLS（008）で達成。オフラインキュー/差分同期はv1.1 |
| ゴミ箱機能 | 低 | ✅ | 論理削除・復元・完全削除（PR #28）+ 30日自動物理削除バッチ（PR #25） |

> **クラウド同期の整理**: 実装計画書の「Supabase Storageとの同期処理」は、撮影画像の Storage アップロード（owner-only RLS でデバイス間共有）として Sprint 1 で達成済み。オフライン撮影のキューイングや差分同期は v1.1 スコープとして切り出す。

### 3.4 Phase 2: 課金・広告（2週間）

**Sprint 4（Week 9-10）: RevenueCat + AdMob**

| タスク | 優先度 | 詳細 |
|---|---|---|
| RevenueCat SDK統合 | 高 | purchases_flutter パッケージ |
| Apple/Googleサブスクプロダクト登録 | 高 | App Store Connect / Google Play Console |
| revenuecat-webhook Edge Function | 高 | Webhook受信→subscriptionsテーブル更新 |
| プラン管理UI | 高 | 購入・復元画面 |
| 有料/無料の制限差別化 | 高 | planに応じた利用回数・ストレージ制御 |
| 無料トライアルフロー | 中 | 7日間トライアル |
| AdMob統合 | 中 | バナー・インタースティシャル・リワード |
| 広告表示ロジック | 中 | プレミアムユーザー非表示判定 |

### 3.5 Phase 3: テスト・リリース準備（3週間）

**Sprint 5（Week 11-12）: QA・最適化**

| タスク | 優先度 | 詳細 |
|---|---|---|
| 総合テスト | 高 | 機能テスト・回帰テスト |
| パフォーマンス最適化 | 高 | 画像キャッシュ・遅延読込・メモリ管理 |
| セキュリティテスト | 高 | RLS検証・APIキー保護確認 |
| UI/UX改善 | 中 | ユーザビリティテスト結果の反映 |
| エラーハンドリング整備 | 中 | オフライン時・API障害時の挙動 |
| エラー監視統合 | 中 | Sentry等 |

**Sprint 6（Week 13）: リリース**

| タスク | 優先度 | 詳細 |
|---|---|---|
| App Store審査申請 | 高 | スクリーンショット・説明文・プライバシーポリシー |
| Google Play審査申請 | 高 | ストアリスティング・コンテンツレーティング |
| プライバシーポリシー作成 | 高 | 個人情報保護法準拠 |
| 利用規約作成 | 高 | サービス利用条件 |
| ランディングページ作成 | 中 | アプリ紹介サイト |
| 運用監視設定 | 中 | ログ・アラート・ダッシュボード |

---

## 4. テスト計画

### 4.1 テスト方針

| テスト種別 | 対象 | ツール | カバレッジ目標 |
|---|---|---|---|
| ユニットテスト | ビジネスロジック・モデル | Flutter Test / Deno.test | 80%以上 |
| ウィジェットテスト | Flutter UI | Flutter Widget Test | 主要画面 |
| Edge Functionテスト | 各Edge Function | Deno.test + supabase CLI | 全エンドポイント |
| E2Eテスト | ユーザーフロー | integration_test | 主要フロー3本 |

### 4.2 主要テストシナリオ

1. **新規登録→写真撮影→画像前処理→AI生成→クリップボードコピー** の一連フロー
2. **無料プラン制限** が正しく機能する（AI生成10回/日上限、超過時429）
3. **RevenueCatでサブスクリプション購入** 後にプレミアム機能が解放される

---

## 5. リリース後運用計画

### 5.1 監視・アラート

| 監視項目 | ツール | アラート条件 |
|---|---|---|
| Edge Functionレスポンスタイム | Sentry | p95 > 5秒 |
| エラーレート | Sentry | 5分間で10件以上 |
| Gemini API使用量 | Google Cloud Console | 日次予算の80%到達 |
| Supabase使用量 | Supabase Dashboard | ストレージ80%到達 |
| アプリクラッシュ | Firebase Crashlytics | クラッシュフリー率 < 99% |
| 月次コスト上限 | usage_logs集計 | 1ユーザー月1万回到達 |

### 5.2 リリース後ロードマップ

| バージョン | 時期 | 主な機能追加 |
|---|---|---|
| v1.1 | リリース後1ヶ月 | バグ修正・パフォーマンス改善・UI調整 |
| v1.2 | リリース後2ヶ月 | モデルカスケード実装（Flash-Lite → Flash自動切替） |
| v1.3 | リリース後3ヶ月 | 年額プラン追加（4,800円）・AI画像加工（背景除去等） |
| v2.0 | リリース後6ヶ月 | SNS直接連携（X / Instagram / TikTok） |

### 5.3 KPI

| 指標 | 目標（リリース後3ヶ月） |
|---|---|
| MAU（月間アクティブユーザー） | 5,000人 |
| DAU / MAU比率 | 30%以上 |
| サブスクリプション転換率 | 5% |
| 平均AI生成回数/ユーザー/日 | 3回 |
| アプリストア評価 | 4.0以上 |
| クラッシュフリー率 | 99.5%以上 |

---

## 6. コスト見積もり

### 6.1 AI API原価（Gemini 2.5 Flash-Lite）

リサイズ後画像 + プロンプト ≒ 1,500入力トークン、構造化出力150トークンと仮定。
1リクエスト約 $0.00021 ≒ **0.032円**

| 月間利用回数 | API原価 | 売上(税抜337円)からの粗利 |
|---|---|---|
| 100回 | 約3円 | 約334円 |
| 1,000回 | 約32円 | 約305円 |
| 5,000回 | 約160円 | 約177円 |
| 10,000回 | 約320円 | 約17円 |

ストア手数料30%控除後でも、月1万回未満なら確実に黒字。

### 6.2 固定費（月額）

| 項目 | 想定月額 |
|---|---|
| Supabase（Free〜Pro） | $0〜25 |
| RevenueCat | $0（月収$2,500まで無料） |
| Firebase | $0（無料枠内） |
| ドメイン・SSL | $15/年 |
| Apple Developer Program | $99/年 |
| Google Play Developer | $25（初回のみ） |
| **合計** | **$0〜25/月**（初期はFreeプランで運用可能） |

v1.5の$95〜225/月から**大幅にコスト削減**（FastAPI用のRailway費用が不要）。

---

## 7. リスク管理

| リスク | 影響度 | 発生確率 | 対策 |
|---|---|---|---|
| Edge Functionsの実行時間制限 | 中 | 中 | AI呼び出しのタイムアウト設定、処理の最適化 |
| Gemini APIのレート制限 | 中 | 中 | リトライ制御、フォールバック（モデル切替） |
| App Store審査リジェクト | 高 | 中 | ガイドライン事前確認、余裕あるスケジュール |
| ユーザーデータ漏洩 | 高 | 低 | RLS徹底、Supabase Secrets、定期セキュリティレビュー |
| AI生成の不適切コンテンツ | 中 | 中 | コンテンツフィルタ、Geminiセーフティ設定活用 |
| 開発遅延 | 中 | 中 | MVP優先、フェーズ分割、スコープ調整 |
| Gemini API仕様変更・料金改定 | 中 | 中 | AIサービス抽象化層で吸収、設定変更のみでモデル切替 |
| RevenueCat料金体系変更 | 低 | 低 | 月収$2,500超時の移行計画を事前に策定 |

---

## 8. 注意事項チェックリスト

### 8.1 必須対応

- [ ] APIキーはFlutterに含めない（Supabase Secretsのみ）
- [ ] 全テーブルでRLSを有効化
- [ ] JWTの期限・更新フローの実装
- [ ] 画像のリサイズ・圧縮を必ず実施（flutter_image_compress）
- [ ] レシート検証はRevenueCat経由でサーバー側で
- [ ] AIサービス層でモデル呼び出しを抽象化

### 8.2 推奨対応

- [ ] デバッグ用にリサイズ後画像のプレビュー機能
- [ ] Edge Function側でのリクエストサイズ上限チェック（≤2MB）
- [ ] 1ユーザーあたりの月次コスト上限設定
- [ ] エラー時の利用回数返却（成功時のみカウント）
- [ ] Sentry等でのエラー監視

### 8.3 将来検討事項

- [ ] バッチ処理が必要になった場合のBatch API活用（50%オフ）
- [ ] 高解像度OCRが必要な場合の長辺1568pxオプション
- [ ] 他社AIモデル（Claude, GPT等）への切替検証
- [ ] AWS統合の必要性が出たらBedrock移行検討
