// ============================================================================
// ai-generate Edge Function
// ============================================================================
// POST /functions/v1/ai-generate
// 画像 + プロンプトを受け取り、AI（Gemini）で構造化出力を生成して返す。
// 利用枠の確保（アトミック）→ AI 呼び出し → 失敗時は枠を返却 → ログ記録の順。
// ============================================================================

import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";
import {
  loadUsageContext,
  logUsage,
  rateLimited,
  refundUsage,
  tryIncrementUsage,
} from "../_shared/usage.ts";
import { createAIService } from "../_shared/ai-service.ts";

/** リクエストサイズ上限（2MB） */
const MAX_BODY_BYTES = 2 * 1024 * 1024;

/** ハッシュタグ生成数の許容範囲（プロンプト注入・コスト膨張を防ぐ） */
const MIN_HASHTAG_COUNT = 1;
const MAX_HASHTAG_COUNT = 30;
const DEFAULT_HASHTAG_COUNT = 10;

const ALLOWED_LANGUAGES = new Set(["ja", "en"]);
const ALLOWED_STYLES = new Set(["poetic", "formal", "casual", "news", "humor"]);
// モバイル側 CaptionLength.promptHint と対応
const ALLOWED_LENGTH_HINTS = new Set(["40〜70字", "80〜140字", "150〜250字"]);

interface RequestBody {
  /** base64 画像（data URL prefix なし） */
  image: string;
  mimeType: string;
  /** "hashtag" | "caption"。プロンプト選択に使用 */
  taskType: "hashtag" | "caption";
  /** 任意指定: 言語・スタイル・件数・文章長ヒント */
  options?: {
    language?: string;
    style?: string;
    count?: number;
    lengthHint?: string;
  };
}

interface SanitizedOptions {
  language: string;
  style: string;
  count: number;
  lengthHint: string | null;
}

const HASHTAG_SCHEMA = {
  type: "object",
  properties: {
    hashtags: { type: "array", items: { type: "string" } },
  },
  required: ["hashtags"],
};

const CAPTION_SCHEMA = {
  type: "object",
  properties: {
    caption: { type: "string" },
    altText: { type: "string" },
  },
  required: ["caption"],
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonError(405, "METHOD_NOT_ALLOWED", "POST のみ受け付けます");
  }

  // ===== 認証 =====
  const user = await authenticate(req);
  if (!user) return unauthorized();

  // ===== サイズチェック =====
  // Content-Length は自己申告値なので先行チェックのみに使い、実バイト数でも検証する
  // （チャンク転送や虚偽の Content-Length による上限バイパスを防ぐ）。
  const contentLength = Number(req.headers.get("Content-Length") ?? "0");
  if (contentLength > MAX_BODY_BYTES) {
    return jsonError(413, "PAYLOAD_TOO_LARGE", "リクエストサイズが上限を超えています");
  }
  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch {
    return jsonError(400, "INVALID_BODY", "リクエストボディの読み取りに失敗しました");
  }
  if (new TextEncoder().encode(rawBody).byteLength > MAX_BODY_BYTES) {
    return jsonError(413, "PAYLOAD_TOO_LARGE", "リクエストサイズが上限を超えています");
  }

  // ===== ボディパース・検証 =====
  let body: RequestBody;
  try {
    body = JSON.parse(rawBody) as RequestBody;
  } catch {
    return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
  }
  if (
    typeof body.image !== "string" || body.image.length === 0 ||
    typeof body.mimeType !== "string" || body.mimeType.length === 0
  ) {
    return jsonError(400, "INVALID_REQUEST", "image / mimeType / taskType は必須です");
  }
  if (body.taskType !== "hashtag" && body.taskType !== "caption") {
    return jsonError(400, "INVALID_REQUEST", "taskType は hashtag / caption を指定してください");
  }

  try {
    // ===== プラン・利用回数チェック（アトミックに枠を確保） =====
    const service = createServiceClient();
    const ctx = await loadUsageContext(service, user.userId);
    const newCount = await tryIncrementUsage(service, user.userId, ctx.dailyLimit);
    if (newCount === null) {
      return rateLimited(0, ctx.dailyLimit);
    }

    // ===== AI 呼び出し =====
    const ai = createAIService();
    const prompt = buildPrompt(body.taskType, sanitizeOptions(body.options));
    const schema = body.taskType === "hashtag" ? HASHTAG_SCHEMA : CAPTION_SCHEMA;

    let aiResponse;
    try {
      aiResponse = await ai.generate({
        image: body.image,
        mimeType: body.mimeType,
        prompt,
        responseSchema: schema,
      });
    } catch (e) {
      console.error("AI generate failed:", e);
      // 失敗時は確保済みの利用枠を返却する（成功時のみカウントの原則）
      await refundUsage(service, user.userId);
      return jsonError(502, "AI_PROVIDER_ERROR", "AI サービスでエラーが発生しました");
    }

    // ===== ログ記録（成功時のみ） =====
    await logUsage(service, {
      userId: user.userId,
      model: aiResponse.model,
      inputTokens: aiResponse.inputTokens,
      outputTokens: aiResponse.outputTokens,
      costUsd: aiResponse.costUsd,
    });

    return new Response(
      JSON.stringify({
        result: aiResponse.result,
        model: aiResponse.model,
        remaining: Math.max(ctx.dailyLimit - newCount, 0),
        limit: ctx.dailyLimit,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    // createServiceClient / createAIService の設定不備等もここで JSON エラーに揃える
    console.error("ai-generate handler error:", e);
    return jsonError(500, "INTERNAL_ERROR", "サーバ内部エラー");
  }
});

// options はクライアント入力なので、プロンプトへ埋め込む前に許容値へ丸める。
function sanitizeOptions(options: RequestBody["options"]): SanitizedOptions {
  const language = typeof options?.language === "string" && ALLOWED_LANGUAGES.has(options.language)
    ? options.language
    : "ja";
  const style = typeof options?.style === "string" && ALLOWED_STYLES.has(options.style)
    ? options.style
    : "casual";
  const count = typeof options?.count === "number" && Number.isInteger(options.count)
    ? Math.min(Math.max(options.count, MIN_HASHTAG_COUNT), MAX_HASHTAG_COUNT)
    : DEFAULT_HASHTAG_COUNT;
  const lengthHint =
    typeof options?.lengthHint === "string" && ALLOWED_LENGTH_HINTS.has(options.lengthHint)
      ? options.lengthHint
      : null;
  return { language, style, count, lengthHint };
}

function buildPrompt(taskType: RequestBody["taskType"], options: SanitizedOptions): string {
  if (taskType === "hashtag") {
    return `あなたは SNS マーケティングの専門家です。
写真を分析し、エンゲージメントを最大化するハッシュタグを ${options.count} 個生成してください。
言語: ${options.language}、スタイル: ${options.style}。
JSON で { "hashtags": [string, ...] } 形式で返してください。`;
  }
  const lengthLine = options.lengthHint ? `文章の長さの目安: ${options.lengthHint}。\n` : "";
  return `あなたはフォトダイアリーの編集者です。
写真の内容を踏まえて、心に残る投稿文を生成してください。
言語: ${options.language}、スタイル: ${options.style}。
${lengthLine}JSON で { "caption": string, "altText": string } 形式で返してください。
altText は視覚障害者向けの代替テキストです。`;
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
