// ============================================================================
// AI サービス抽象化層
// ============================================================================
// 実装計画書 §2.3 に従い、AI モデル呼び出しをサービス層で抽象化する。
// 設定（AIModelConfig）の差し替えだけで Gemini → Claude / OpenAI へ切替可能。
//
// 現状実装: Gemini Provider（Google Generative Language API）。
// Claude / OpenAI を追加する場合は Provider クラスを新設し、
// createAIService のスイッチに 1 行追加するだけで良い。
// ============================================================================

import type { AIModelConfig, GenerateRequest, GenerateResponse } from "./types.ts";

export interface AIService {
  generate(req: GenerateRequest): Promise<GenerateResponse>;
}

// ----------------------------------------------------------------------------
// Gemini Provider
// ----------------------------------------------------------------------------

/** Gemini 2.5 Flash-Lite の概算コスト（USD / 1M トークン） */
const GEMINI_COST = {
  "gemini-2.5-flash-lite": { input: 0.10, output: 0.40 },
  "gemini-2.5-pro": { input: 1.25, output: 5.00 },
} as const;

class GeminiProvider implements AIService {
  constructor(private readonly config: AIModelConfig, private readonly apiKey: string) {}

  async generate(req: GenerateRequest): Promise<GenerateResponse> {
    const url =
      `${this.config.endpoint}/models/${this.config.model}:generateContent?key=${this.apiKey}`;

    const body = {
      contents: [
        {
          role: "user",
          parts: [
            { text: req.prompt },
            {
              inline_data: {
                mime_type: req.mimeType,
                data: req.image,
              },
            },
          ],
        },
      ],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: req.responseSchema,
        temperature: 0.7,
      },
    };

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text();
      throw new Error(`Gemini API error ${res.status}: ${text}`);
    }

    const json = await res.json() as GeminiResponse;
    const candidate = json.candidates?.[0];
    if (!candidate?.content?.parts?.[0]?.text) {
      throw new Error("Gemini response did not contain text content");
    }
    const result = JSON.parse(candidate.content.parts[0].text) as Record<string, unknown>;

    const inputTokens = json.usageMetadata?.promptTokenCount ?? 0;
    const outputTokens = json.usageMetadata?.candidatesTokenCount ?? 0;
    const costUsd = estimateGeminiCost(this.config.model, inputTokens, outputTokens);

    return { result, model: this.config.model, inputTokens, outputTokens, costUsd };
  }
}

interface GeminiResponse {
  candidates?: Array<{
    content?: { parts?: Array<{ text?: string }> };
    finishReason?: string;
  }>;
  usageMetadata?: {
    promptTokenCount?: number;
    candidatesTokenCount?: number;
    totalTokenCount?: number;
  };
}

function estimateGeminiCost(model: string, inputTokens: number, outputTokens: number): number {
  const rate = GEMINI_COST[model as keyof typeof GEMINI_COST] ?? GEMINI_COST["gemini-2.5-flash-lite"];
  return (inputTokens / 1_000_000) * rate.input + (outputTokens / 1_000_000) * rate.output;
}

// ----------------------------------------------------------------------------
// Factory
// ----------------------------------------------------------------------------

/** デフォルト設定（環境変数で上書き可能） */
export function defaultConfig(): AIModelConfig {
  return {
    provider: (Deno.env.get("AI_PROVIDER") ?? "gemini") as AIModelConfig["provider"],
    model: Deno.env.get("AI_MODEL") ?? "gemini-2.5-flash-lite",
    apiKeySecret: "GEMINI_API_KEY",
    endpoint: "https://generativelanguage.googleapis.com/v1beta",
  };
}

export function createAIService(config: AIModelConfig = defaultConfig()): AIService {
  const apiKey = Deno.env.get(config.apiKeySecret);
  if (!apiKey) {
    throw new Error(`AI API key not set: ${config.apiKeySecret}`);
  }

  switch (config.provider) {
    case "gemini":
      return new GeminiProvider(config, apiKey);
    // TODO: Claude / OpenAI Provider を追加する場合はここに case を増やす
    case "anthropic":
      throw new Error("anthropic provider not implemented yet");
    case "openai":
      throw new Error("openai provider not implemented yet");
    default:
      throw new Error(`Unknown AI provider: ${config.provider}`);
  }
}
