# dAIary（ダイアリー）

写真に、言葉を添えて。

写真で日々を記録し、AI が言葉を添えるフォトダイアリーアプリ。Diary の中に「AI」を埋め込んだ造語で、ロゴでは d**AI**ary と表記する。

## モノレポ構成

```text
daiary/
├── mobile/             # Flutter アプリ（iOS / Android）
├── supabase/           # Supabase 設定（migrations, Edge Functions）
├── docs/               # 設計ドキュメント・要件定義・実装計画
├── .github/workflows/  # CI/CD（パスフィルタによる差分ビルド）
├── Makefile            # 統一タスクランナー
└── docker-compose.yml  # ローカル開発用（Supabase Local）
```

## 技術スタック

| レイヤー       | 技術                                                  |
| -------------- | ----------------------------------------------------- |
| モバイル       | Flutter（Riverpod + Go Router）                       |
| バックエンド   | Supabase Edge Functions（Deno / TypeScript）          |
| 生成 AI        | Gemini API（初期: 2.5 Flash-Lite、設定で切替可能）    |
| データベース   | Supabase（Auth / Storage / PostgreSQL / Secrets）     |
| 課金           | RevenueCat                                            |
| 広告           | Google AdMob                                          |

## クイックスタート

詳細手順は [docs/setup.md](docs/setup.md) を参照。

```bash
# 依存インストール
make setup

# Supabase ローカル起動
make supabase-start
make supabase-db-reset

# Edge Functions ローカル起動
make functions-serve

# Flutter 起動（別ターミナル）
cd mobile && flutter run
```

## ドキュメント

- [要件定義書](docs/dAIary_requirements.md)
- [実装計画書](docs/dAIary_implementation_plan.md)
- [API 仕様](docs/api-spec.md)
- [アーキテクチャ](docs/architecture.md)
- [ER 図](docs/er-diagram.md)
- [プロンプト設計](docs/prompt-design.md)
- [セットアップ手順](docs/setup.md)
- [Phase 0 外部タスク](docs/phase0-external-tasks.md)

## 開発フロー

- ブランチ戦略: `main` ← `develop` ← `feature/{mobile|functions|infra}/<topic>`
- コミット規約: Conventional Commits ベース（`feat:`, `fix:`, `docs:`, `refactor:`, ...）
- CI: 変更パスに応じて `mobile-ci` / `functions-ci` / `db-migration` が走る

## ライセンス

未定（個人開発プロジェクト）
