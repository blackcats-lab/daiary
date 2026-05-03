# dAIary ER 図

```mermaid
erDiagram
    AUTH_USERS ||--o| SUBSCRIPTIONS : "1:1"
    AUTH_USERS ||--o{ DAILY_USAGE : "1:N (per day)"
    AUTH_USERS ||--o{ USAGE_LOGS : "1:N"
    AUTH_USERS ||--o{ PHOTOS : "1:N"
    AUTH_USERS ||--o{ ALBUMS : "1:N"
    PHOTOS ||--o{ ALBUM_PHOTOS : "1:N"
    ALBUMS ||--o{ ALBUM_PHOTOS : "1:N"
    PHOTOS |o--o| ALBUMS : "cover_photo_id"

    AUTH_USERS {
      uuid id PK
      text email
      timestamptz created_at
    }

    SUBSCRIPTIONS {
      uuid user_id PK,FK
      text plan "free | premium"
      timestamptz expires_at
      text revenuecat_id
      timestamptz updated_at
    }

    DAILY_USAGE {
      uuid user_id PK,FK
      date usage_date PK
      int count
    }

    USAGE_LOGS {
      uuid id PK
      uuid user_id FK
      timestamptz created_at
      text model
      int input_tokens
      int output_tokens
      numeric cost_usd
    }

    PHOTOS {
      uuid id PK
      uuid user_id FK
      text storage_path
      text thumbnail_path
      varchar original_filename
      bigint file_size
      int width
      int height
      jsonb exif_data
      jsonb ai_tags
      boolean is_favorite
      timestamptz deleted_at
      timestamptz created_at
    }

    ALBUMS {
      uuid id PK
      uuid user_id FK
      varchar name
      uuid cover_photo_id FK
      boolean is_public
      varchar share_token
      timestamptz created_at
      timestamptz updated_at
    }

    ALBUM_PHOTOS {
      uuid album_id PK,FK
      uuid photo_id PK,FK
      int sort_order
      timestamptz added_at
    }
```

## 主要制約・インデックス

- 全テーブルで RLS 有効化
- `subscriptions.plan` は `CHECK (plan IN ('free', 'premium'))`
- `daily_usage` PK = `(user_id, usage_date)`（アトミック UPSERT 用）
- `photos`: 未削除 + 新着順インデックス、お気に入り部分インデックス、`ai_tags` GIN インデックス
- `album_photos` PK = `(album_id, photo_id)`
- `albums.cover_photo_id` は `ON DELETE SET NULL`
- `auth.users` 削除時は全関連テーブルが `ON DELETE CASCADE`

## RPC

- `increment_usage(p_user_id uuid) RETURNS int` — 当日 `daily_usage` を UPSERT で +1 し最新値を返す。`SECURITY DEFINER` + `service_role` のみ実行可
- `set_updated_at()` — `subscriptions` / `albums` の `BEFORE UPDATE` トリガーで `updated_at` を `now()` に更新
