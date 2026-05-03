// ============================================================================
// ai-generate Edge Function
// ============================================================================
// POST /functions/v1/ai-generate
// 画像 + プロンプトを受け取り、AI（Gemini）で構造化出力を生成して返す。
// 利用回数チェック → AI 呼び出し → カウンタ加算 → ログ記録の順。
// ============================================================================

import { authenticate, createServiceClient, unauthorized } from "../_shared/auth.ts";
import {
  incrementUsage,
  loadUsageContext,
  logUsage,
  rateLimited,
} from "../_shared/usage.ts";
import { createAIService } from "../_shared/ai-service.ts";

/** リクエストサイズ上限（2MB） */
const MAX_BODY_BYTES = 2 * 1024 * 1024;

interface RequestBody {
  /** base64 画像（data URL prefix なし） */
  image: string;
  mimeType: string;
  /** "hashtag" | "caption" など。プロンプト選択に使用 */
  taskType: "hashtag" | "caption";
  /** 任意指定: 言語・スタイル・件数 */
  options?: {
    language?: string;
    style?: string;
    count?: number;
  };
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
  const contentLength = Number(req.headers.get("Content-Length") ?? "0");
  if (contentLength > MAX_BODY_BYTES) {
    return jsonError(413, "PAYLOAD_TOO_LARGE", "リクエストサイズが上限を超えています");
  }

  // ===== ボディパース =====
  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return jsonError(400, "INVALID_JSON", "JSON のパースに失敗しました");
  }
  if (!body.image || !body.mimeType || !body.taskType) {
    return jsonError(400, "INVALID_REQUEST", "image / mimeType / taskType は必須です");
  }

  // ===== プラン・利用回数チェック =====
  const service = createServiceClient();
  const ctx = await loadUsageContext(service, user.userId);
  if (ctx.todayCount >= ctx.dailyLimit) {
    return rateLimited(0, ctx.dailyLimit);
  }

  // ===== AI 呼び出し =====
  const ai = createAIService();
  const prompt = buildPrompt(body);
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
    return jsonError(502, "AI_PROVIDER_ERROR", "AI サービスでエラーが発生しました");
  }

  // ===== カウンタ加算 + ログ記録（成功時のみ） =====
  try {
    await incrementUsage(service, user.userId);
  } catch {
    // RPC 失敗時はログのみ残し、レスポンスは返す（ユーザー体験優先）
  }
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
      remaining: ctx.dailyLimit - (ctx.todayCount + 1),
      limit: ctx.dailyLimit,
    }),
    { status: 200, headers: { "Content-Type": "application/json" } },
  );
});

function buildPrompt(body: RequestBody): string {
  const language = body.options?.language ?? "ja";
  const style = body.options?.style ?? "casual";
  const count = body.options?.count ?? 10;

  if (body.taskType === "hashtag") {
    return `あなたは SNS マーケティングの専門家です。
写真を分析し、エンゲージメントを最大化するハッシュタグを ${count} 個生成してください。
言語: ${language}、スタイル: ${style}。
JSON で { "hashtags": [string, ...] } 形式で返してください。`;
  }
  return `あなたはフォトダイアリーの編集者です。
写真の内容を踏まえて、心に残る投稿文を生成してください。
言語: ${language}、スタイル: ${style}。
JSON で { "caption": string, "altText": string } 形式で返してください。
altText は視覚障害者向けの代替テキストです。`;
}

function jsonError(status: number, code: string, message: string): Response {
  return new Response(
    JSON.stringify({ code, message }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}
