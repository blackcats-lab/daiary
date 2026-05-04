# dAIary プロンプト設計

`ai-generate` Edge Function で使用するプロンプトと JSON Schema の定義。
モデル切替（Gemini → Claude / OpenAI）の影響を抑えるため、出力フォーマットは
プロバイダ非依存の JSON Schema として定義する。

## 共通方針

- 言語は `options.language`（既定 `ja`）に従う
- スタイルは `options.style`（`casual` / `formal` / `poetic` / `business` 等）
- 画像は単一・base64 で渡す。テキストパートを 1 件、画像パートを 1 件添える
- 出力は必ず JSON Schema に沿った structured output（`responseMimeType: "application/json"` + `responseSchema`）

## 1. ハッシュタグ生成

### システムプロンプト（テキストパート先頭）

```text
あなたは SNS マーケティングの専門家です。
写真を分析し、エンゲージメントを最大化するハッシュタグを {count} 個生成してください。
言語: {language}、スタイル: {style}。
- ハッシュタグは「#」を含めて返す
- 重複・無意味なタグは除外
- 写真の被写体・色調・季節・場所・感情のいずれかを反映
JSON で { "hashtags": [string, ...] } 形式で返してください。
```

### JSON Schema

```json
{
  "type": "object",
  "properties": {
    "hashtags": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": ["hashtags"]
}
```

### 出力例

```json
{
  "hashtags": [
    "#夕暮れ",
    "#golden_hour",
    "#tokyotower",
    "#街歩き",
    "#cityscape",
    "#blue_hour",
    "#日々の記録"
  ]
}
```

## 2. 投稿文（キャプション）生成

### システムプロンプト

```text
あなたはフォトダイアリーの編集者です。
写真の内容を踏まえて、心に残る投稿文を生成してください。
言語: {language}、スタイル: {style}。
- caption は 80〜140 字程度
- altText は視覚障害者向けの代替テキスト（写真に何が写っているか客観的に）
JSON で { "caption": string, "altText": string } 形式で返してください。
```

### JSON Schema

```json
{
  "type": "object",
  "properties": {
    "caption": { "type": "string" },
    "altText": { "type": "string" }
  },
  "required": ["caption"]
}
```

### 出力例

```json
{
  "caption": "夕陽が街を金色に染める時間。今日もこの瞬間に間に合った。",
  "altText": "夕暮れ時の都市風景。ビル群のシルエットが赤紫色の空に浮かんでいる。"
}
```

## 拡張予定スキーマ（v1.1 以降）

### 詩・短文（poetry）

```json
{
  "type": "object",
  "properties": {
    "title": { "type": "string" },
    "lines": { "type": "array", "items": { "type": "string" } }
  },
  "required": ["lines"]
}
```

### EXIF を活かした撮影メモ

写真の EXIF（撮影地・日時・F 値）を `text` パートに加え、メタデータを織り込んだ文章を生成。

## モデル切替時の注意

- **Claude**: `responseSchema` 相当は tool use（`input_schema`）か `output_format: json_object` を使う
- **OpenAI**: `response_format: { type: "json_schema", json_schema: { ... } }`
- 各実装で同じ `result` 形状を返すことが abstraction 層の責務
