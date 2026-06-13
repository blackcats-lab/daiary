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

自分の写真一覧（未削除）を新しい順に返す。

クエリパラメータ:

| name     | type    | default | 説明                                                            |
| -------- | ------- | ------- | --------------------------------------------------------------- |
| `limit`  | int     | 50      | 取得件数。最大 100、不正値や 0 以下は 50 にフォールバック       |
| `before` | ISO8601 | -       | この `created_at` より古いものだけ取得（ページング用）          |

レスポンス 200:

```json
{
  "photos": [
    {
      "id": "uuid",
      "storage_path": "user_uuid/2026/05/abc.jpg",
      "thumbnail_path": "user_uuid/2026/05/abc_thumb.jpg",
      "original_filename": "IMG_1234.HEIC",
      "file_size": 1543210,
      "width": 4032,
      "height": 3024,
      "exif_data": {},
      "ai_tags": [],
      "is_favorite": false,
      "caption": null,
      "alt_text": null,
      "created_at": "2026-05-04T10:00:00.000Z"
    }
  ],
  "next_before": "2026-05-04T10:00:00.000Z"
}
```

`next_before` は次ページ取得用カーソル。返却件数が `limit` 未満なら `null`。

### GET /photos/:id

写真 1 件の詳細を返す。

レスポンス 200:

```json
{ "photo": { "id": "uuid", ...同上, "deleted_at": null } }
```

エラー: 400 INVALID_ID（UUID 形式不正）/ 404 NOT_FOUND

### POST /photos

メタデータ作成。Storage 本体のアップロードは Flutter 側で別経路（Storage SDK）で実施し、生成された `storage_path` を渡す前提。

リクエスト:

```json
{
  "storage_path": "user_uuid/2026/05/abc.jpg",
  "thumbnail_path": "user_uuid/2026/05/abc_thumb.jpg",
  "original_filename": "IMG_1234.HEIC",
  "file_size": 1543210,
  "width": 4032,
  "height": 3024,
  "exif_data": {},
  "ai_tags": []
}
```

| field          | required | 備考                                  |
| -------------- | -------- | ------------------------------------- |
| `storage_path` | ✓        | 唯一の必須フィールド                  |
| 他             | -        | 省略時は null / 空 (`{}` or `[]`)     |

レスポンス 201:

```json
{ "photo": { "id": "新規UUID", ... } }
```

### PATCH /photos/:id

更新可能フィールド: `is_favorite` (boolean), `ai_tags` (array), `caption` (string|null), `alt_text` (string|null)。
他のフィールドは送信されても無視される。
いずれも未指定の場合 400 INVALID_REQUEST。
`caption` / `alt_text` は `null` を明示送信すると消去できる。

リクエスト例:

```json
{ "is_favorite": true }
```

```json
{ "caption": "夕陽が街を金色に染める時間。", "alt_text": "夕方の街並み" }
```

レスポンス 200: 更新後の `{ "photo": {...} }`。

### DELETE /photos/:id

論理削除（`deleted_at = now()` を set）。物理削除はバッチで 30 日後に実施予定。

レスポンス 200:

```json
{ "id": "uuid", "deleted": true }
```

エラー: 404 NOT_FOUND（既に削除済み or 自分の写真でない）

## 3. albums

アルバム CRUD と写真の関連付け。`album_photos` 中間テーブルを介して photos と多対多。
写真の関連付けは専用エンドポイント `POST/DELETE /albums/:id/photos` で複数件を一括操作する。

### GET /albums

自分のアルバム一覧。

レスポンス 200:

```json
{
  "albums": [
    {
      "id": "uuid",
      "name": "夏の思い出",
      "cover_photo_id": "uuid|null",
      "cover_thumbnail_path": "user_uuid/.../abc_thumb.jpg|null",
      "is_public": false,
      "share_token": null,
      "photo_count": 12,
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

### GET /albums/:id

アルバム詳細 + 含まれる写真。論理削除済み (`deleted_at IS NOT NULL`) の写真は除外。

レスポンス 200:

```json
{
  "album": {
    "id": "uuid",
    "name": "夏の思い出",
    "cover_photo_id": "uuid|null",
    "is_public": false,
    "share_token": null,
    "created_at": "...",
    "updated_at": "..."
  },
  "photos": [
    {
      "id": "uuid",
      "storage_path": "...",
      "thumbnail_path": "...",
      "width": 4032,
      "height": 3024,
      "caption": null,
      "ai_tags": [],
      "is_favorite": false,
      "sort_order": 0,
      "added_at": "..."
    }
  ]
}
```

エラー: 400 INVALID_ID / 404 NOT_FOUND

### POST /albums

```json
{
  "name": "夏の思い出",
  "cover_photo_id": "uuid|null",
  "is_public": false
}
```

| field | required | 備考 |
|---|---|---|
| `name` | ✓ | 1〜100 字。空白のみは不可 |
| `cover_photo_id` | - | 指定時は所有確認 |
| `is_public` | - | 既定 false |

レスポンス 201: `{ "album": { ...GET と同じシェイプ + photo_count: 0, cover_thumbnail_path: null } }`

### PATCH /albums/:id

更新可能フィールド: `name` (1〜100 字), `cover_photo_id` (uuid|null, null 明示で消去), `is_public` (boolean), `share_token` (string|null)。
いずれも未指定の場合 400 INVALID_REQUEST。

### DELETE /albums/:id

物理削除（`album_photos` は CASCADE）。photos 自体は残る。

レスポンス 200: `{ "id": "uuid", "deleted": true }`

### POST /albums/:id/photos

アルバムに写真を一括追加する。`sort_order` はサーバ側で `MAX(sort_order) + 1` から連番割り振り。
所有者でない / 論理削除済みの写真、既にアルバムに含まれる写真はサイレント除外せず `skipped` 配列で返す。

リクエスト:

```json
{ "photo_ids": ["uuid1", "uuid2"] }
```

| 制約 | 値 |
|---|---|
| photo_ids 件数 | 1〜100 |

レスポンス 200:

```json
{
  "added": ["uuid1"],
  "skipped": [
    { "photo_id": "uuid2", "reason": "already_in_album" },
    { "photo_id": "uuid3", "reason": "not_owned_or_deleted" }
  ]
}
```

skip 理由コード:

- `already_in_album` — 既にアルバムに含まれている
- `not_owned_or_deleted` — 自分の写真でない、または論理削除済み

エラー: 400 INVALID_REQUEST / 400 INVALID_ID / 404 NOT_FOUND（アルバム）

### DELETE /albums/:id/photos

アルバムから写真を一括削除する（写真自体は残る）。

リクエスト:

```json
{ "photo_ids": ["uuid1", "uuid2"] }
```

レスポンス 200:

```json
{ "removed": ["uuid1", "uuid2"] }
```

実際に中間テーブルから削除された photo_id のみ返す。元々関連付けが無かった id は単に含まれない。

エラー: 400 INVALID_REQUEST / 400 INVALID_ID / 404 NOT_FOUND（アルバム）

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

## 5. photos-cleanup

論理削除から 30 日経過した写真を物理削除するバッチ。GitHub Actions の日次スケジュール
（`.github/workflows/photos-cleanup.yml`）から呼ばれる内部エンドポイント。

### POST /photos-cleanup

ヘッダー: `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`（完全一致のみ許可。ユーザー JWT では呼べない）

`deleted_at` が 30 日より古い写真を最大 100 件ずつバッチで処理する。各写真について
**Storage の実ファイル（原寸 + サムネイル）→ DB 行**の順で削除し、Storage 削除に
失敗した写真はスキップして行を残す（次回実行で再試行）。

レスポンス 200:

```json
{ "deleted": 12, "skipped": 0, "cutoff": "2026-05-14T00:00:00.000Z" }
```

エラー: 401 UNAUTHORIZED / 500 CONFIG_ERROR（キー未設定）/ 500 DB_ERROR
