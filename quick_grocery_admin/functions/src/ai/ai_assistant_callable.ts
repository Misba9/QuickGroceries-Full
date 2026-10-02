import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { ChatTurn, runGroceryAssistant } from "./assistant_engine";
import { persistAiChatTurn } from "./ai_chat_persist";
// GEMINI_API_KEY: set as Functions secret or env — see gemini_config.ts
import "./gemini_config";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function parseHistory(raw: unknown): ChatTurn[] {
  if (!Array.isArray(raw)) return [];
  const out: ChatTurn[] = [];
  for (const item of raw.slice(-12)) {
    if (!item || typeof item !== "object") continue;
    const roleRaw = str((item as { role?: unknown }).role).toLowerCase();
    const role: "user" | "assistant" =
      roleRaw === "assistant" || roleRaw === "model" ? "assistant" : "user";
    const text = str(
      (item as { text?: unknown; content?: unknown }).text ??
        (item as { content?: unknown }).content,
    );
    if (!text) continue;
    out.push({ role, text: text.slice(0, 2000) });
  }
  return out;
}

/**
 * Grocery AI assistant callable.
 *
 * Request:
 *   { message: string, history?: [{role,text}], sessionId?: string }
 * Response:
 *   { reply, productIds, quickReplies, intent, source, latencyMs }
 *
 * After a successful reply, persists the turn to `ai_chat_sessions` for admin.
 */
export const aiGroceryAssistant = onCall(
  {
    ...callableBaseOptions(),
    // Bind after creating the secret:
    //   firebase functions:secrets:set GEMINI_API_KEY
    // then add: secrets: geminiSecretBindings(),
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to chat with the assistant.");
    }

    const message = str(req.data?.message);
    if (!message) {
      throw new HttpsError("invalid-argument", "message is required.");
    }
    if (message.length > 2000) {
      throw new HttpsError("invalid-argument", "message is too long.");
    }

    const history = parseHistory(req.data?.history);
    const sessionId = str(req.data?.sessionId) || "default";
    const started = Date.now();

    console.log(
      "[aiGroceryAssistant] in",
      JSON.stringify({
        uid,
        sessionId,
        messageLen: message.length,
        historyLen: history.length,
      }),
    );

    try {
      const result = await runGroceryAssistant({ uid, message, history });
      const latencyMs = Date.now() - started;
      console.log(
        "[aiGroceryAssistant] out",
        JSON.stringify({
          uid,
          sessionId,
          source: result.source,
          intent: result.intent,
          productCount: result.productIds.length,
          latencyMs,
        }),
      );

      try {
        await persistAiChatTurn({
          uid,
          sessionId,
          userMessage: message,
          reply: result.reply,
          productIds: result.productIds,
          quickReplies: result.quickReplies,
          intent: result.intent,
          source: result.source,
          latencyMs,
        });
      } catch (persistErr) {
        // Never fail the user chat if admin transcript write fails.
        console.error("[aiGroceryAssistant] persist failed", persistErr);
      }

      return {
        success: true,
        reply: result.reply,
        productIds: result.productIds,
        quickReplies: result.quickReplies,
        intent: result.intent,
        source: result.source,
        latencyMs,
        sessionId,
      };
    } catch (e) {
      console.error("[aiGroceryAssistant] error", e);
      throw new HttpsError(
        "internal",
        "The assistant hit a snag. Please try again in a moment.",
      );
    }
  },
);
