import { defineSecret } from "firebase-functions/params";
import { HttpsError } from "firebase-functions/v2/https";

/** Google AI Studio / Gemini API key — never ship in the Flutter app. */
export const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

export function geminiSecretBindings() {
  return [GEMINI_API_KEY];
}

export function readGeminiApiKey(): string | null {
  const key = (process.env.GEMINI_API_KEY || "").trim();
  return key.length > 0 ? key : null;
}

export function requireGeminiApiKey(): string {
  const key = readGeminiApiKey();
  if (!key) {
    throw new HttpsError(
      "failed-precondition",
      "AI assistant is not configured. Set GEMINI_API_KEY in Cloud Functions secrets.",
    );
  }
  return key;
}
