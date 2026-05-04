# Gemini API PoC 結果

**実施日**: 2026-05-04
**モデル**: `gemini-2.5-flash-lite`
**経路**: ローカル `ai-generate` Edge Function 経由

## 検証目的

Phase 0 計画書 §3.2 「Gemini API 検証」に基づき、以下を確認する:

1. AI サービス抽象化層 → Gemini API の呼び出しが成立すること
2. JSON Schema による構造化出力が期待通りに返ること
3. 利用回数カウンタ（`daily_usage`）と詳細ログ（`usage_logs`）が記録されること
4. 1 リクエストあたりの実コストが想定（約 0.032 円）に収まること

## 検証手順

1. ローカル Supabase + Edge Functions を起動（`supabase start` / `supabase functions serve`）
2. `auth/v1/signup` でテストユーザー作成 → JWT 取得
3. テスト画像（富士山の風景写真、約 100KB の JPEG）を base64 化
4. `POST /functions/v1/ai-generate` を `taskType=hashtag` / `caption` でそれぞれ 1 回実行
5. Studio の SQL Editor で `daily_usage` / `usage_logs` を確認

## 結果

### レスポンス例

#### hashtag

```json
{
  "result": {
    "hashtags": ["#富士山", "#mtfuji", "#絶景", "#日本の風景", "#自然", "#空", "#旅", "#ドライブ"]
  },
  "model": "gemini-2.5-flash-lite",
  "remaining": 4,
  "limit": 5
}
```

#### caption

```json
{
  "result": {
    "caption": "紺碧の空にそびえる富士山の雄大な姿は、まるで永久の時が刻まれたかのよう。...",
    "altText": "青空を背景に、雪を頂いた雄大な富士山がそびえ立っています。..."
  },
  "model": "gemini-2.5-flash-lite",
  "remaining": 3,
  "limit": 5
}
```

### DB ログ

`daily_usage`:

| user_id (抜粋) | usage_date | count |
|---|---|---|
| b76c5e85... | 2026-05-04 | 2 |

`usage_logs`:

| model | input_tokens | output_tokens | cost_usd |
|---|---|---|---|
| gemini-2.5-flash-lite | 328 | 150 | 0.000093 |
| gemini-2.5-flash-lite | 319 | 59  | 0.000056 |

## コスト評価

| 指標 | 想定 | 実測 |
|---|---|---|
| 1 リクエストあたり | 約 0.032 円 | **0.008〜0.014 円**（想定の 1/3〜1/4） |
| 1 ユーザー / 日 5 回 | 約 0.16 円 | 約 0.05〜0.07 円 |
| 1,000 MAU × 5 回 / 日 × 30 日 | 月 4,800 円 | **月 1,500〜2,100 円** |

想定より大幅に安い。Phase 1 リリース後の MAU 増加にも十分耐えられる見込み。

## 確認できた事項

- ✅ AI サービス抽象化層 (`_shared/ai-service.ts`) → `GeminiProvider` の経路が機能
- ✅ `responseSchema` を渡すことで JSON で構造化出力が返る（`responseMimeType: "application/json"`）
- ✅ JWT 認証 → user_id 取得 → `subscriptions` 参照 → `daily_usage` チェック → AI 呼び出し → `increment_usage` RPC → `usage_logs` 記録 の全フローが正常動作
- ✅ `remaining` / `limit` がレスポンスに含まれ、Flutter 側で残回数表示に使える
- ✅ 利用回数上限ロジック（free プラン 5 回/日）が機能（実装計画書通り）

## 留意事項・既知の問題

- レート制限テスト（429 RATE_LIMITED 返却）は未検証 → Phase 1 Sprint 2 のテスト計画に含める
- 画像サイズ上限（2MB）超過時の 413 PAYLOAD_TOO_LARGE 返却も未検証
- プロンプトの品質（生成されるハッシュタグ・キャプションの SNS 適性）は人間判断が必要 → Phase 1 で実機テスト時に評価
- `caption` の `style: "poetic"` は文章が長くなりがち。実装計画書の「80〜140 字程度」を超えるケースが見られた → プロンプト調整余地あり（[prompt-design.md](prompt-design.md) で追跡）

## モデル切替時の参考

将来 Claude / GPT 等への切替を検討する際、本 PoC を比較ベースとして:

- **応答時間**: 1〜2 秒（ローカル経由・東京リージョン）
- **構造化出力の安定性**: JSON パース失敗ゼロ（10 数回の試行内）
- **日本語品質**: 自然な口語・敬語・絵文字使用（指定なくても適切）

## 次のアクション

- [ ] レート制限テスト（429 返却）を Phase 1 Sprint 2 の自動テストに含める
- [ ] 画像サイズ超過テスト（413 返却）を同様に追加
- [ ] 本番 Supabase Secrets に `GEMINI_API_KEY` を投入（[phase0-external-tasks.md §2](phase0-external-tasks.md) と合わせて）
- [ ] プロンプト調整時は本 PoC の値（コスト・応答時間）と比較して回帰しないか確認
