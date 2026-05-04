# dAIary API 仕様（Edge Functions）

ベース URL: `${SUPABASE_URL}/functions/v1`

全エンドポイント共通:

- リクエストヘッダー: `Authorization: Bearer <Supabase JWT>` 必須（`revenuecat-webhook` を除く）
- レスポンスは `Content-Type: application/json`
- 共通エラー形式: `{ "code": string, "message": string, "details"?: any }`

## 共通エラーコード

| HTTP | code               | 意味 |
| ---- | ------------------ | ---- |
| 400  | INVALID_JSON       | リクエストボディが JSON として不正 |
| 400  | INVALID_REQUEST    | 必須フィールド欠落 / 形式不正 |
| 401  | UNAUTHORIZED       | JWT 不正 / 期限切れ / 未提供 |
| 405  | METHOD_NOT_ALLOWED | HTTP メソッド非対応 |
| 413  | PAYLOAD_TOO_LARGE  | リクエストサイズ > 2MB |
| 429  | RATE_LIMITED       | 当日の利用回数上限を超過 |
| 500  | DB_ERROR           | DB アクセス失敗 |
| 502  | AI_PROVIDER_ERROR  | AI プロバイダ呼び出し失敗 |

## 1. ai-generate

写真とプロンプトから構造化結果（ハッシュタグ／投稿文）を生成する。

### POST /ai-generate

#### Request

```json
{
  "image": "<base64 string, no data URL prefix>",
  "mimeType": "image/jpeg",
  "taskType": "hashtag" | "caption",
  "options": {
    "language": "ja",
    "style": "casual",
    "count": 10
  }
}
```

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| image | string (base64) | ✓ | 画像本体。Flutter 側で長辺 1024px / JPEG q80 まで前処理してから送る |
| mimeType | string | ✓ | `image/jpeg` / `image/png` / `image/webp` |
| taskType | string | ✓ | `hashtag` または `caption` |
| options.language | string | - | 既定 `ja` |
| options.style | string | - | 既定 `casual` |
| options.count | int | - | hashtag 個数。既定 10 |

#### Response 200

```json
{
  "result": {
    "hashtags": ["#sunset", "#blueHour", "#tokyo"]
  },
  "model": "gemini-2.5-flash-lite",
  "remaining": 4,
  "limit": 5
}
```

`taskType: "caption"` の場合は `result` が `{ "caption": string, "altText": string }` になる。

#### エラー

- 401 UNAUTHORIZED
- 413 PAYLOAD_TOO_LARGE（>2MB）
- 429 RATE_LIMITED（プラン上限）
- 502 AI_PROVIDER_ERROR

## 2. photos

写真メタデータの CRUD。実体（画像ファイル）は Supabase Storage の `photos` バケットに別経路でアップロードする。

### GET /photos

自分の写真一覧（未削除）を新しい順に返す。クエリ: `?limit=50&before=<created_at>`

### GET /photos/:id

写真 1 件の詳細（EXIF・AI タグ含む）を返す。

### POST /photos

```json
{
  "storage_path": "user_uuid/2026/05/abc.jpg",
  "thumbnail_path": "user_uuid/2026/05/abc_thumb.jpg",
  "original_filename": "IMG_1234.HEIC",
  "file_size": 1543210,
  "width": 4032,
  "height": 3024,
  "exif_data": { },
  "ai_tags": []
}
```

### PATCH /photos/:id

更新可能フィールド: `is_favorite`, `ai_tags`

### DELETE /photos/:id

論理削除（`deleted_at = now()` を set）。

> Phase 0 時点では雛形のみ。実装は Phase 1（Sprint 1）。

## 3. albums

アルバム CRUD。

### GET /albums

自分のアルバム一覧。

### GET /albums/:id

アルバム詳細 + 含まれる写真。

### POST /albums

```json
{
  "name": "夏の思い出",
  "is_public": false
}
```

### PATCH /albums/:id

更新可能フィールド: `name`, `cover_photo_id`, `is_public`, `share_token`

### DELETE /albums/:id

物理削除（`album_photos` は CASCADE）。

> Phase 0 時点では雛形のみ。実装は Phase 1（Sprint 3）。

## 4. revenuecat-webhook

RevenueCat からのサブスク状態変更通知を受ける。

### POST /revenuecat-webhook

ヘッダー: `Authorization: <REVENUECAT_WEBHOOK_AUTH>`（RevenueCat ダッシュボードで設定した固定値）

ペイロード: RevenueCat の Webhook 仕様に準拠（<https://www.revenuecat.com/docs/integrations/webhooks/event-flows-and-payloads>）

処理対象イベント:

| event.type | 対応 |
| ---------- | ---- |
| INITIAL_PURCHASE / RENEWAL / PRODUCT_CHANGE / UNCANCELLATION | `subscriptions.plan = premium`, `expires_at` 更新 |
| CANCELLATION / EXPIRATION / BILLING_ISSUE | `subscriptions.plan = free`, `expires_at = null` |
| その他 | スキップ（200 を返す） |

レスポンス: `{ "ok": true }` または上記共通エラー形式。
