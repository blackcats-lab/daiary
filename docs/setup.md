# dAIary ローカル開発セットアップ

## 前提

| ツール | バージョン | 用途 |
| ------ | ---------- | ---- |
| Flutter SDK | >= 3.22 | mobile/ ビルド |
| Dart | >= 3.4 | 同梱 |
| Supabase CLI | latest | ローカル Supabase 起動 |
| Docker Desktop | latest | Supabase Local が内部で利用 |
| Deno | >= 1.x | Edge Functions のローカルテスト |
| Make | - | タスクランナー |
| Xcode / Android Studio | latest | iOS / Android ビルド |

### Windows でのインストール例

```powershell
# Make
winget install GnuWin32.Make
# winget 経由は PATH に自動追加されないため、ユーザー環境変数 PATH に
# C:\Program Files (x86)\GnuWin32\bin を手動追加する。

# Supabase CLI（Scoop 推奨）
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
# Scoop の shim パス（例: C:\Users\<name>\scoop\shims）も PATH に必要。
```

PowerShell を入れ直してから `make --version` / `supabase --version` で確認。

## 1. リポジトリ取得

```bash
git clone https://github.com/<owner>/daiary.git
cd daiary
```

## 2. Flutter ネイティブフォルダ生成

リポジトリには `mobile/android/`, `mobile/ios/` を含めていない（プラットフォーム差分が大きく、生成物の方が安定）。
初回のみ次を実行する。

```bash
cd mobile
flutter create .
flutter pub get
cd ..
```

`flutter create .` は既存の `lib/`, `pubspec.yaml`, `test/` を上書きしない。

## 3. 環境変数

```bash
cp mobile/.env.example mobile/.env
cp supabase/.env.example supabase/.env.local
cp supabase/functions/.env.example supabase/functions/.env.local
```

それぞれ実値（Supabase URL / anon key / Gemini API key 等）を埋める。

ローカル Supabase の値は次で確認できる。

```bash
supabase status
```

## 4. Supabase Local 起動

```bash
make supabase-start         # supabase start
make supabase-db-reset      # migrations 001-007 + seed.sql を流す
```

Studio は <http://127.0.0.1:54323> で開ける。

### `supabase start` が ECR レート制限で失敗する場合

`public.ecr.aws` の匿名 pull レート上限に達すると `toomanyrequests: Rate exceeded` で停止する。
Phase 0 で必須でない `mailpit` 等を除外して起動できる:

```bash
supabase start -x mailpit
```

DB / Auth / Storage / Edge Functions / Studio はこれで起動する。
1 時間程度待てばレート制限がリセットされ通常起動も可能。

## 5. Edge Functions ローカル起動

別ターミナルで:

```bash
make functions-serve
# = supabase functions serve --env-file supabase/.env.local
```

`http://127.0.0.1:54321/functions/v1/<function-name>` で待ち受ける。

## 6. Flutter 起動

```bash
cd mobile
flutter run
```

## 7. テスト

```bash
make test          # mobile-test + functions-test
make lint          # mobile-lint + functions-lint
```

## トラブルシューティング

### `supabase start` が失敗する

- Docker Desktop が起動しているか確認
- `supabase stop` してからやり直す
- ポート競合（54321-54324, 54322）を `lsof -i` で確認

### Flutter で `dotenv` が読み込めない

- `mobile/.env` が存在するか確認
- `pubspec.yaml` の `assets:` に `.env` が入っているか確認

### Edge Function で `GEMINI_API_KEY not set`

- `supabase/.env.local` または `supabase/functions/.env.local` に値を入れたか確認
- `supabase functions serve` を `--env-file` 付きで再起動

### Windows で `make` / `supabase` コマンドが見つからない

- `Get-Command make` / `Get-Command supabase` で PATH を確認
- 上記「前提 / Windows でのインストール例」のとおり PATH を追加してから PowerShell を開き直す
- 一時的なら `$env:Path += ";C:\Program Files (x86)\GnuWin32\bin"` をセッションに追加

## 関連ドキュメント

- [API 仕様](api-spec.md)
- [アーキテクチャ](architecture.md)
- [ER 図](er-diagram.md)
- [プロンプト設計](prompt-design.md)
- [Phase 0 外部タスク](phase0-external-tasks.md)
