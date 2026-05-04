# dAIary 開発ガイド（Claude 向け）

このファイルは Claude Code がこのリポジトリで作業する際に自動で読み込まれる。
人間向けの README は [README.md](README.md) を参照。

---

## プロジェクト概要

**dAIary（ダイアリー）** — 写真に、言葉を添えて。
写真で日々を記録し、AI（Gemini）が言葉を添えるフォトダイアリーアプリ。
ロゴでは d**AI**ary と表記する造語。

- ターゲット: スマホで日常を記録したい個人ユーザー
- マネタイズ: フリーミアム（無料 + プレミアムサブスク + 広告）
- リリース目標: Phase 3 完了後（プロジェクト開始から約 13 週間）

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| モバイル | Flutter (Riverpod + GoRouter + Repository pattern) |
| バックエンド | Supabase Edge Functions (Deno / TypeScript) |
| 生成 AI | Gemini API（初期: 2.5 Flash-Lite。設定で切替可能） |
| データベース | Supabase Postgres（RLS + RPC） |
| 認証 | Supabase Auth (JWT, email + Google + Apple) |
| ストレージ | Supabase Storage (`photos` bucket) |
| 課金 | RevenueCat（Phase 2 で統合） |
| 広告 | Google AdMob（Phase 2 で統合） |
| CI/CD | GitHub Actions（パスフィルタによる差分ビルド） |

---

## モノレポ構成

```text
daiary/
├── mobile/             # Flutter アプリ（iOS / Android）
├── supabase/
│   ├── config.toml     # Supabase CLI ローカル設定
│   ├── migrations/     # 001-007 の DB スキーマ
│   ├── functions/      # Edge Functions (Deno)
│   │   ├── _shared/    # 認証・利用回数・AI 抽象化層
│   │   ├── ai-generate/        # 本実装済み（PoC 検証済み）
│   │   ├── photos/             # 雛形のみ（Phase 1 で本実装）
│   │   ├── albums/             # 雛形のみ（Phase 1 Sprint 3）
│   │   └── revenuecat-webhook/ # 雛形のみ（Phase 2）
│   └── seed.sql
├── docs/               # 全設計ドキュメント
├── .github/workflows/  # mobile-ci / functions-ci / db-migration
├── Makefile            # 統一タスクランナー
└── docker-compose.yml
```

詳細なファイル意図は [docs/architecture.md](docs/architecture.md) を参照。

---

## 重要ドキュメント

作業前に該当するものを参照すること:

| ファイル | 用途 |
|---|---|
| [docs/dAIary_requirements.md](docs/dAIary_requirements.md) | v2.0 要件定義（不変・正典） |
| [docs/dAIary_implementation_plan.md](docs/dAIary_implementation_plan.md) | v2.0 実装計画・スプリント割り当て |
| [docs/architecture.md](docs/architecture.md) | システム構成・データフロー |
| [docs/api-spec.md](docs/api-spec.md) | Edge Functions の API 仕様 |
| [docs/er-diagram.md](docs/er-diagram.md) | DB スキーマ |
| [docs/prompt-design.md](docs/prompt-design.md) | AI プロンプト・JSON Schema |
| [docs/setup.md](docs/setup.md) | ローカル開発手順 |
| [docs/gemini-poc-result.md](docs/gemini-poc-result.md) | 実 API での動作確認結果 |
| [docs/phase0-external-tasks.md](docs/phase0-external-tasks.md) | Claude が実行できない外部タスク |

---

## 開発ワークフロー

### ブランチ戦略

```text
main ← develop ← feature/{mobile|functions|infra}/<topic>
                ← docs/<topic>
                ← fix/<topic>
```

- `main` / `develop` への直 push は **branch protection で禁止**
- 必ずフィーチャーブランチを切って **PR 経由で develop に取り込む**
- `develop → main` も PR 経由（リリースタイミングで実施）
- 必須 status checks: `Analyze & Test` / `Lint & Test` / `Validate migrations on local Supabase`

### コミットメッセージ規約

[Conventional Commits](https://www.conventionalcommits.org/ja/) ベース。**type は英語、subject は日本語**。

```text
<type>: <日本語の subject>
```

| Type | 用途 |
|---|---|
| `feat` | 新機能の追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（フォーマット等） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・修正 |
| `build` | ビルドシステム / 外部依存の変更 |
| `ci` | CI/CD 設定の変更 |
| `chore` | 上記に当てはまらない雑務 |
| `revert` | 過去のコミットの取り消し |
| `wip` | 作業途中の一時保存（メイン取り込み前に squash/rebase 推奨） |

例:

```text
feat(mobile): カメラ撮影画面を追加
fix(functions): JWT検証時のheader大小文字を許容
docs: setup手順にECRレート制限の回避策を追記
```

1 行目は **50 文字以内**を目安、末尾にピリオド・句点を付けない。

---

## 作業時の注意

### 環境

- **Windows + PowerShell** が主環境。`bash` / `find` / `cp` 等が動作しないことを前提に CI スクリプトと手順を組む。
- Supabase CLI は **v2 系**。`supabase status` の出力で従来の `anon key` / `service_role key` は **`Publishable`** / **`Secret`** に名称変更されている（`sb_publishable_...` / `sb_secret_...` 形式）。値は従来通り `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` 環境変数に投入。
- Edge Functions ランタイムは起動時に `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` を**自動注入**する。`.env.local` に書いても "Env name cannot start with SUPABASE_, skipping" で無視されるが、害は無い。
- `supabase start` で ECR レート制限 (`toomanyrequests`) を踏んだら `supabase start -x mailpit` で必須でないコンテナを除外して起動する。

### シークレットの取り扱い

- `.env.local` 系は **`.gitignore` 対象**。コミットしない。
- **API キー等の機密値はチャットに貼らない**ようユーザーに依頼する。Claude のコンテキストに残ると無効化が必要になる。
- `supabase/.env.local` / `supabase/functions/.env.local` / `mobile/.env` は `.example` テンプレートをコピーして使う。

### コード規約

- **Dart**: `dart format` 規則に従う。CI で `dart format --set-exit-if-changed` が走るので、push 前にローカルで `dart format lib test` を実行。
- **Deno (TypeScript)**: `deno fmt` 規則に従う。CI で `deno fmt --check` が走る。
- **Deno lint の罠**: `_` プレフィックス引数（`_service` 等）は既に未使用許容。`// deno-lint-ignore no-unused-vars` を付けると `ban-unused-ignore` エラーになる。
- **Async without await**: Deno lint は `async function` の本体に `await` が無いとエラー。雛形（501 を返すだけ）では `async` を付けない。

### Flutter / Riverpod / Repository 流儀（Sprint 1 で確立）

- **コード生成**: `freezed 3.x` + `riverpod_generator 4.x` + `json_serializable` を使う。CI で `dart run build_runner build --delete-conflicting-outputs` が format/analyze/test の前に走る。生成ファイル（`*.g.dart` / `*.freezed.dart`）は `.gitignore` 対象でコミットしない。
- **freezed 3.x の文法**: `@freezed abstract class Xxx with _$Xxx { const factory Xxx(...) = _Xxx; }` の形（`abstract` 必須）。
- **riverpod_generator の命名**: `class AuthNotifier extends _$AuthNotifier` で定義した Notifier は **`authProvider`** という変数名で公開される（`Notifier` サフィックスを除く）。`AuthNotifier` 全体を識別子に使う書き方（`authNotifierProvider`）にはならないので注意。
- **Repository pattern**: `data/datasources` → `data/repositories` → `domain/repositories`（abstract）→ `presentation/providers` の 4 層。Domain 層が SDK 型を直接扱わず、`AuthFailure` 等の共通例外で吸収する。
- **`AuthUser` 名前衝突**: `supabase_flutter` も `AuthUser` を export する。自前の Domain entity を import する側で `import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;` する。
- **GoRouter の認証 redirect**: `refreshListenable` に Riverpod 状態を ChangeNotifier 経由で渡し、`redirect` で auth 状態を見て `/login` / `/home` に振り分ける。`/splash` を中間状態として用意し、初期ロード中はそこに留める。
- **analysis_options.yaml**: `*.g.dart` / `*.freezed.dart` を analyze の `exclude` に**入れてはいけない**。生成された Provider クラス・mixin が「未定義」と判定される。
- **custom_lint / riverpod_lint**: 一時的に除外中（`analyzer 7.6` との互換問題）。Phase 1 後半で再評価する。

### CI ハマりどころ

- `mobile-ci` は `flutter analyze` の前に **`cp .env.example .env` が必要**。`pubspec.yaml` の `assets:` で `.env` を宣言しているため、ファイルが無いと `asset_does_not_exist` warning で fail する。
- `mobile-ci` で `dart run build_runner build --delete-conflicting-outputs` を pub get の後に実行する。生成ファイルが無いと analyzer が大量に Undefined エラーを吐く。
- `functions-ci` の `deno test` はテストファイル 0 件だと exit 1 になる。Phase 0 では `find` でファイル有無を確認してスキップする条件分岐を入れている（Phase 1 でテストを書き始めれば自動的に走る）。
- パスフィルタ動作: `mobile/**` / `supabase/functions/**` / `supabase/migrations/**` のいずれかに変更がある場合のみ該当ワークフローが走る。docs だけの変更では CI は走らない。

### マイグレーション

- 既存の 001-007 マイグレーションは**変更しない**（本番に適用済みになる前提）。
- 修正・追加は **新しい番号**（008_xxx.sql）で連番ファイルを追加する。
- ローカル検証は `make supabase-db-reset`。
- 全テーブルで RLS 必須。書き込み系の特権操作（`subscriptions` / `usage_logs` / `increment_usage`）は service_role のみ。

### AI サービスの拡張

- `supabase/functions/_shared/ai-service.ts` で provider を抽象化済み。
- Claude / OpenAI を追加する場合は新 Provider クラスを実装し、`createAIService` の switch に case を 1 行追加する。
- 出力スキーマは provider 非依存の JSON Schema で定義（[docs/prompt-design.md](docs/prompt-design.md) 参照）。

---

## Phase 進捗

| Phase | 状態 | 期間 |
|---|---|---|
| **Phase 0: 設計・準備** | ✅ 完了（Gemini PoC 含む） | Sprint 0 / 2 週間 |
| Phase 1 Sprint 1: 認証 + カメラ基盤 | 🚧 進行中（photos CRUD・認証 + ログイン画面 完了。次: カメラ撮影 + Storage） | Week 3-4 |
| Phase 1 Sprint 2: AI 生成機能 | 未着手 | Week 5-6 |
| Phase 1 Sprint 3: アルバム + 写真管理 | 未着手 | Week 7-8 |
| Phase 2: 課金・広告 | 未着手 | Week 9-10 |
| Phase 3: テスト・リリース準備 | 未着手 | Week 11-13 |

未消化の Phase 0 外部タスクは [docs/phase0-external-tasks.md](docs/phase0-external-tasks.md) を参照。

---

## よく使うコマンド

```powershell
# ローカル Supabase 起動・リセット
supabase start -x mailpit
supabase db reset

# Edge Functions ローカル起動
supabase functions serve --env-file supabase/functions/.env.local

# Flutter 開発
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 生成必要なら
flutter analyze
flutter test
flutter run

# フォーマット（CI と同じ規則）
cd mobile && dart format lib test
# Deno 側は CI に任せるか deno fmt
```

詳細は [docs/setup.md](docs/setup.md) と [Makefile](Makefile) を参照。

---

## 行動原則

- 何か変更する前にまずユーザーに**意図を確認**する（Phase 1 の各タスクは特に）。
- **PR ベース**で作業する。develop 直 push はしない（branch protection で防がれる）。
- 不明な仕様は実装計画書 v2.0 と要件定義書 v2.0 を**正典**として扱う。両書と齟齬がある場合は実装より要件定義を優先。
- 既存マイグレーションは触らない（追加で対応）。
- 雛形を本実装に置き換えるときは、対応する `// TODO(phaseN):` コメントを必ず探して整合させる。
