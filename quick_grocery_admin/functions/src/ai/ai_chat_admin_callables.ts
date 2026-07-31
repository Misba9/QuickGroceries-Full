import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";

const db = admin.firestore();
const SESSIONS = "ai_chat_sessions";

function tsToIso(v: unknown): string | null {
  if (v && typeof v === "object" && "toDate" in v) {
    try {
      return (v as admin.firestore.Timestamp).toDate().toISOString();
    } catch {
      return null;
    }
  }
  if (typeof v === "string" && v.trim()) return v;
  return null;
}

/**
 * Admin: list AI chat sessions (bypasses client Firestore rules).
 */
export const listAiChatSessionsCallable = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const limitRaw = Number(req.data?.limit ?? 80);
    const limit = Number.isFinite(limitRaw)
      ? Math.min(Math.max(Math.floor(limitRaw), 1), 200)
      : 80;

    const snap = await db
      .collection(SESSIONS)
      .orderBy("updatedAt", "desc")
      .limit(limit)
      .get();

    const items = snap.docs.map((d) => {
      const data = d.data() ?? {};
      return {
        id: d.id,
        uid: String(data.uid ?? ""),
        sessionId: String(data.sessionId ?? ""),
        lastMessage: String(data.lastMessage ?? ""),
        customerName: String(data.customerName ?? ""),
        customerPhone: String(data.customerPhone ?? ""),
        lastIntent: String(data.lastIntent ?? ""),
        lastSource: String(data.lastSource ?? ""),
        messageCount:
          typeof data.messageCount === "number" ? data.messageCount : 0,
        updatedAt: tsToIso(data.updatedAt),
        createdAt: tsToIso(data.createdAt),
      };
    });

    return { success: true, items, count: items.length };
  },
);

/**
 * Admin: list messages for one AI chat session.
 */
export const listAiChatMessagesCallable = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const sessionDocId = String(req.data?.sessionDocId ?? "").trim();
    if (!sessionDocId) {
      throw new HttpsError("invalid-argument", "sessionDocId is required.");
    }

    const snap = await db
      .collection(SESSIONS)
      .doc(sessionDocId)
      .collection("messages")
      .orderBy("createdAtMs", "asc")
      .limit(300)
      .get();

    const items = snap.docs.map((d) => {
      const data = d.data() ?? {};
      const products = data.productIds;
      return {
        id: d.id,
        role: String(data.role ?? "assistant"),
        text: String(data.text ?? ""),
        createdAtMs:
          typeof data.createdAtMs === "number" ? data.createdAtMs : 0,
        intent: data.intent != null ? String(data.intent) : null,
        source: data.source != null ? String(data.source) : null,
        productIds: Array.isArray(products)
          ? products.map((e) => String(e))
          : [],
        latencyMs:
          typeof data.latencyMs === "number" ? data.latencyMs : null,
        createdAt: tsToIso(data.createdAt),
      };
    });

    return { success: true, items, count: items.length };
  },
);
