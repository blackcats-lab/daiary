// ============================================================================
// 共通型定義
// ============================================================================
// Edge Functions 全体で参照する型を集約する。
// 実装計画書 §2.3 の AIModelConfig / GenerateRequest / GenerateResponse を踏襲。
// ============================================================================

export type Plan = "free" | "premium";

export type AIProvider = "gemini" | "openai" | "anthropic";

export interface AIModelConfig {
  provider: AIProvider;
  model: string;
  /** Supabase Secrets / 環境変数のキー名 */
  apiKeySecret: string;
  /** プロバイダのベース URL */
  endpoint: string;
}

export interface GenerateRequest {
  /** base64 エンコード済み画像（data URL prefix を含まない） */
  image: string;
  /** 画像の MIME タイプ（例: "image/jpeg"） */
  mimeType: string;
  /** プロンプト本文 */
  prompt: string;
  /** 構造化出力の JSON Schema */
  responseSchema: Record<string, unknown>;
}

export interface GenerateResponse {
  /** AI が返した構造化結果（responseSchema に沿う） */
  result: Record<string, unknown>;
  /** 使用したモデル名 */
  model: string;
  /** 入力トークン数 */
  inputTokens: number;
  /** 出力トークン数 */
  outputTokens: number;
  /** 概算コスト（USD） */
  costUsd: number;
}

export interface UsageContext {
  userId: string;
  plan: Plan;
  /** 当日のこれまでの利用回数（増分前） */
  todayCount: number;
  /** プラン上限（free=N, premium=Infinity 等） */
  dailyLimit: number;
}

export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}
