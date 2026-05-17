import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { assertNotificationAdmin } from "./notification_admin_assert";

const db = admin.firestore();

const KNOWN_TOPICS = new Set([
  "all_users",
  "offers",
  "vegetables",
  "dairy",
  "premium_users",
  "active_users",
  "new_users",
]);

export function normalizeTopic(raw: string): string {
  const s = (raw || "all_users")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\-_.~%]/g, "_");
  return s || "all_users";
}

export function str(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

export function resolveTopic(data: Record<string, unknown>): string {
  const explicit = normalizeTopic(str(data.topic));
  if (explicit && KNOWN_TOPICS.has(explicit)) return explicit;
  const audience = normalizeTopic(
    str(data.targetAudience || data.targetType || "all_users")
  );
  if (KNOWN_TOPICS.has(audience)) return audience;
  return "all_users";
}

function personalizeMessage(message: string, name: string): string {
  const n = name || "there";
  return message
    .replace(/\{\{userName\}\}/gi, n)
    .replace(/\{\{orderId\}\}/gi, "—")
    .replace(/\{\{userId\}\}/gi, "");
}

async function addNotificationLog(entry: Record<string, unknown>) {
  return db.collection("notification_logs").add({
    ...entry,
    provider: "FCM",
    openedCount: 0,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function buildDataPayload(parts: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(parts)) {
    out[k] = v ?? "";
  }
  out.click_action = "FLUTTER_NOTIFICATION_CLICK";
  return out;
}

async function sendToFcmTopic(opts: {
  title: string;
  body: string;
  topic: string;
  imageUrl: string;
  deepLink: string;
  redirectType: string;
  ctaLabel: string;
  soundType: string;
  logId: string;
  campaignId?: string;
}): Promise<string> {
  const data = buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink,
    redirectType: opts.redirectType,
    imageUrl: opts.imageUrl,
    ctaLabel: opts.ctaLabel,
    soundType: opts.soundType,
    logId: opts.logId,
    campaignId: opts.campaignId || "",
  });

  const message: admin.messaging.Message = {
    topic: opts.topic,
    notification: { title: opts.title, body: opts.body },
    data,
  };

  if (opts.imageUrl) {
    message.android = {
      notification: { imageUrl: opts.imageUrl },
    };
    message.apns = {
      payload: { aps: { "mutable-content": 1 } },
      fcmOptions: { imageUrl: opts.imageUrl },
    };
  }

  return admin.messaging().send(message);
}

async function sendToToken(opts: {
  token: string;
  title: string;
  body: string;
  imageUrl: string;
  deepLink: string;
  redirectType: string;
  ctaLabel: string;
  soundType: string;
  logId: string;
}): Promise<string> {
  const data = buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink,
    redirectType: opts.redirectType,
    imageUrl: opts.imageUrl,
    ctaLabel: opts.ctaLabel,
    soundType: opts.soundType,
    logId: opts.logId,
  });

  const message: admin.messaging.Message = {
    token: opts.token,
    notification: { title: opts.title, body: opts.body },
    data,
  };

  if (opts.imageUrl) {
    message.android = {
      notification: { imageUrl: opts.imageUrl },
    };
    message.apns = {
      payload: { aps: { "mutable-content": 1 } },
      fcmOptions: { imageUrl: opts.imageUrl },
    };
  }

  return admin.messaging().send(message);
}

export type TopicSendResult = {
  success: true;
  messageId: string;
  logId: string;
  topic: string;
};

/** Shared topic broadcast — used by callable + HTTP (CORS) handlers. */
export async function runSendTopicNotification(
  data: Record<string, unknown>
): Promise<TopicSendResult> {
  const title = str(data.title);
  const message = str(data.message || data.body);
  const topic = resolveTopic(data);
  const imageUrl = str(data.imageUrl);
  const deepLink = str(data.deepLink);
  const redirectType = str(data.redirectType);
  const ctaLabel = str(data.ctaLabel);
  const soundType = str(data.soundType);

  if (!title || !message) {
    throw new HttpsError("invalid-argument", "title and message are required.");
  }

  const logRef = await addNotificationLog({
    title,
    message,
    topic,
    userId: "",
    phone: "",
    status: "pending",
    imageUrl,
    deepLink,
    redirectType,
    ctaLabel,
    soundType,
  });

  try {
    const messageId = await sendToFcmTopic({
      title,
      body: message,
      topic,
      imageUrl,
      deepLink,
      redirectType,
      ctaLabel,
      soundType,
      logId: logRef.id,
    });
    await logRef.update({
      status: "sent",
      messageId,
      sentAt: FieldValue.serverTimestamp(),
    });
    return {
      success: true,
      messageId,
      logId: logRef.id,
      topic,
    };
  } catch (e: unknown) {
    const err = e as { message?: string };
    await logRef.update({
      status: "failed",
      error: err.message || String(e),
    });
    throw new HttpsError("internal", err.message || "FCM topic send failed");
  }
}

export type SingleSendResult = {
  success: true;
  messageId: string;
  logId: string;
};

/** Shared single-user push — used by callable + HTTP handlers. */
export async function runSendSingleNotification(
  data: Record<string, unknown>
): Promise<SingleSendResult> {
  const userId = str(data.userId);
  const title = str(data.title);
  const message = str(data.message || data.body);
  const imageUrl = str(data.imageUrl);
  const deepLink = str(data.deepLink);
  const redirectType = str(data.redirectType);
  const ctaLabel = str(data.ctaLabel);
  const soundType = str(data.soundType);

  if (!userId || !title || !message) {
    throw new HttpsError(
      "invalid-argument",
      "userId, title, and message are required."
    );
  }

  const cust = await db.collection("customers").doc(userId).get();
  if (!cust.exists) {
    throw new HttpsError("not-found", "Customer not found.");
  }
  const c = cust.data() || {};
  const token = str(c.fcmToken || c.fcm_token);
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "Customer has no FCM token (app must register for push)."
    );
  }
  const name = str(c.name);
  const body = personalizeMessage(message, name);
  const phone = str(c.phone);

  const logRef = await addNotificationLog({
    title,
    message: body,
    topic: "",
    userId,
    phone,
    status: "pending",
    imageUrl,
    deepLink,
    redirectType,
    ctaLabel,
    soundType,
  });

  try {
    const messageId = await sendToToken({
      token,
      title,
      body,
      imageUrl,
      deepLink,
      redirectType,
      ctaLabel,
      soundType,
      logId: logRef.id,
    });
    await logRef.update({
      status: "sent",
      messageId,
      sentAt: FieldValue.serverTimestamp(),
    });
    return { success: true, messageId, logId: logRef.id };
  } catch (e: unknown) {
    const err = e as { message?: string };
    await logRef.update({
      status: "failed",
      error: err.message || String(e),
    });
    throw new HttpsError("internal", err.message || "FCM single send failed");
  }
}

/** Verifies Firebase ID token + admin access for raw HTTP endpoints. */
export async function assertHttpNotificationAdmin(
  authHeader: string | undefined
): Promise<string> {
  if (!authHeader?.startsWith("Bearer ")) {
    throw new Error("Missing Authorization: Bearer <Firebase ID token>");
  }
  const idToken = authHeader.slice("Bearer ".length).trim();
  if (!idToken) {
    throw new Error("Empty bearer token");
  }
  const decoded = await admin.auth().verifyIdToken(idToken);
  await assertNotificationAdmin(decoded.uid);
  return decoded.uid;
}
