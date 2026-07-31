import * as admin from "firebase-admin";

export type AiChatPersistInput = {
  uid: string;
  sessionId: string;
  userMessage: string;
  reply: string;
  productIds: string[];
  quickReplies: string[];
  intent: string;
  source: string;
  latencyMs: number;
};

/**
 * Persists one user↔assistant turn for admin visibility.
 *
 * Schema:
 *   ai_chat_sessions/{uid}_{sessionId}
 *   ai_chat_sessions/{uid}_{sessionId}/messages/{autoId}
 *   users/{uid}/ai_chats/{sessionId}  (mirror meta)
 */
export async function persistAiChatTurn(input: AiChatPersistInput): Promise<void> {
  const db = admin.firestore();
  const now = admin.firestore.FieldValue.serverTimestamp();
  const safeSession =
    input.sessionId.replace(/[/\s]/g, "_").slice(0, 120) || "default";
  const sessionDocId = `${input.uid}_${safeSession}`.slice(0, 700);
  const sessionRef = db.collection("ai_chat_sessions").doc(sessionDocId);
  const userSessionRef = db
    .collection("users")
    .doc(input.uid)
    .collection("ai_chats")
    .doc(safeSession);
  const messagesCol = sessionRef.collection("messages");

  let customerName = "";
  let customerPhone = "";
  try {
    const cust = await db.collection("customers").doc(input.uid).get();
    if (cust.exists) {
      const d = cust.data() ?? {};
      customerName = String(d.name ?? d.userName ?? "").trim();
      customerPhone = String(d.phoneNumber ?? d.phone ?? "").trim();
    }
  } catch {
    // Non-fatal.
  }

  const preview =
    input.userMessage.length > 160
      ? `${input.userMessage.slice(0, 157)}…`
      : input.userMessage;

  const existing = await sessionRef.get();
  const baseMeta = {
    uid: input.uid,
    sessionId: safeSession,
    updatedAt: now,
    lastMessage: preview,
    lastRole: "assistant" as const,
    lastIntent: input.intent,
    lastSource: input.source,
    customerName,
    customerPhone,
    messageCount: admin.firestore.FieldValue.increment(2),
  };

  const sessionMeta = existing.exists
    ? baseMeta
    : { ...baseMeta, createdAt: now };

  const tick = Date.now();
  const batch = db.batch();
  batch.set(sessionRef, sessionMeta, { merge: true });
  batch.set(userSessionRef, sessionMeta, { merge: true });

  batch.set(messagesCol.doc(), {
    role: "user",
    text: input.userMessage.slice(0, 4000),
    createdAt: now,
    createdAtMs: tick,
    uid: input.uid,
  });
  batch.set(messagesCol.doc(), {
    role: "assistant",
    text: input.reply.slice(0, 8000),
    createdAt: now,
    createdAtMs: tick + 1,
    uid: input.uid,
    productIds: input.productIds.slice(0, 12),
    quickReplies: input.quickReplies.slice(0, 8),
    intent: input.intent,
    source: input.source,
    latencyMs: input.latencyMs,
  });

  await batch.commit();
}
