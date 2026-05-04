# dAIary アーキテクチャ

## システム全体構成

```text
┌─────────────────┐                           ┌──────────────────────────────┐
│  Flutter App    │                           │   Supabase (single tenant)    │
│ (iOS / Android) │                           │                              │
│                 │  ── HTTPS / JWT ───────▶  │  Auth                         │
│  Riverpod       │                           │  Postgres (+ RLS, RPC)        │
│  GoRouter       │  ── Storage SDK ───────▶  │  Storage (photos bucket)      │
│  Repositories   │                           │  Edge Functions (Deno)        │
│  - Supabase SDK │                           │   ├─ ai-generate              │
│  - Camera       │                           │   ├─ photos                   │
│  - ImagePicker  │                           │   ├─ albums                   │
│                 │                           │   └─ revenuecat-webhook ◀──┐  │
└─────────────────┘                           └──────────────────────────────┘
        │                                                            │      │
        │ purchases_flutter                                          │      │
        ▼                                                            │      │
┌─────────────────┐  Webhook (HTTPS)                                 │      │
│   RevenueCat    │ ─────────────────────────────────────────────────┘      │
└─────────────────┘                                                         │
                                                                            │
        │ google_mobile_ads                                                 │
        ▼                                                                   │
┌─────────────────┐                                                         │
│  Google AdMob   │                                                         │
└─────────────────┘                                                         │
                                                                            │
                              ┌───────────────────────────┐                 │
   Edge Function (ai-generate)│   Google Generative AI    │◀────────────────┘
   ──────────────────────────▶│  (Gemini 2.5 Flash-Lite)  │  画像 + Prompt
                              └───────────────────────────┘
```

## 主要データフロー

### AI 生成フロー

1. Flutter: 画像を長辺 1024px / JPEG q80 に圧縮（`flutter_image_compress`）
2. Flutter: `Supabase.functions.invoke('ai-generate', body: {...})`（JWT 自動付与）
3. Edge Function `ai-generate`:
   - JWT 検証（`_shared/auth.ts`）
   - リクエストサイズチェック（≤ 2MB）
   - `subscriptions.plan` と `daily_usage.count` を取得（`_shared/usage.ts`）
   - 上限超過なら 429
   - `_shared/ai-service.ts` 経由で Gemini を呼び出し（`responseSchema` で構造化出力）
   - 成功時: `increment_usage(p_user_id)` RPC でカウンタ +1（アトミック）
   - `usage_logs` に model / tokens / cost を INSERT
4. Flutter: 結果を画面に表示

### サブスク状態同期フロー

1. ユーザーが App Store / Play Store で課金
2. RevenueCat がイベントを集約
3. RevenueCat → `revenuecat-webhook`（HTTPS、Authorization ヘッダー検証）
4. Edge Function: `event.type` を判定し `subscriptions` テーブルを upsert

## モジュール分割方針（Flutter）

`mobile/lib/`:

- `config/` — 環境変数 / テーマ / ルーティング（アプリ起動時の固定設定）
- `core/` — 全 feature から参照される横断的ユーティリティ
- `features/<name>/` — Clean Architecture 風の 3 層（`data` / `domain` / `presentation`）
- `services/` — 外部 SDK（Supabase / AdMob / RevenueCat / Share）の薄いラッパー

`features/<name>/`:

- `data/` — Supabase / API からの取得・変換（`datasources/`, `repositories/`, `models/`）
- `domain/` — エンティティと抽象 repository インターフェース
- `presentation/` — Riverpod プロバイダ + 画面 + ウィジェット

## AI サービス抽象化方針

`supabase/functions/_shared/ai-service.ts` で以下を実現:

```ts
interface AIService {
  generate(req: GenerateRequest): Promise<GenerateResponse>;
}
```

- `createAIService(config)` ファクトリで provider をスイッチ
- `AIModelConfig` を環境変数（`AI_PROVIDER`, `AI_MODEL`）で上書き可能
- 新プロバイダ（Claude, OpenAI 等）追加は Provider クラスを 1 つ実装し、`createAIService` の `switch` に case を 1 行加えるだけ
- 入出力スキーマ（`responseSchema`）はプロバイダ非依存の JSON Schema として定義

## セキュリティ方針

- Gemini API キーは Supabase Secrets / Edge Function 環境変数のみに保管。Flutter には絶対に含めない
- 全テーブルで RLS 有効化。ユーザーは自分の `user_id` の行のみ操作可
- 書き込み系の特権操作（`subscriptions` 更新, `usage_logs` INSERT, `increment_usage`）は service_role のみ
- JWT は Supabase Auth が自動でリフレッシュ。Flutter 側の `flutter_secure_storage` でトークン保管
- Webhook は固定の Authorization 値で検証
