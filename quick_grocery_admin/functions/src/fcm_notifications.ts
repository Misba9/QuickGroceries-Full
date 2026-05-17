import * as admin from "firebase-admin";
import {
  FieldValue,
  Timestamp,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { assertNotificationAdmin } from "./notification_admin_assert";
import { callableBaseOptions, REGION } from "./https_callable_options";
import {
  resolveTopic,
  runSendSingleNotification,
  runSendTopicNotification,
  str,
} from "./fcm_notification_exec";

const db = admin.firestore();

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

export const sendTopicNotification = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    try {
      await assertNotificationAdmin(request.auth?.uid);
      const data = (request.data || {}) as Record<string, unknown>;
      const result = await runSendTopicNotification(data);
      return {
        ...result,
        ok: true,
      };
    } catch (e: unknown) {
      if (e instanceof HttpsError) throw e;
      logger.error("sendTopicNotification_unexpected", e);
      throw new HttpsError(
        "internal",
        "Unexpected error while sending topic notification."
      );
    }
  }
);

export const sendSingleNotification = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const result = await runSendSingleNotification(data);
    return { ...result, ok: true };
  }
);

export const scheduleNotification = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const title = str(data.title);
    const message = str(data.message || data.body);
    const scheduledIso = str(data.scheduledAt);
    const kind = str(data.kind || "topic") === "single" ? "single" : "topic";
    const targetUserId = str(data.userId || data.targetUserId);
    const imageUrl = str(data.imageUrl);
    const deepLink = str(data.deepLink);
    const redirectType = str(data.redirectType);
    const ctaLabel = str(data.ctaLabel);
    const soundType = str(data.soundType);
    const topic = resolveTopic(data);

    if (!title || !message || !scheduledIso) {
      throw new HttpsError(
        "invalid-argument",
        "title, message, and scheduledAt are required."
      );
    }
    if (kind === "single" && !targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "userId is required for single-user scheduled notifications."
      );
    }

    const scheduledAt = Timestamp.fromDate(new Date(scheduledIso));
    if (scheduledAt.toMillis() <= Date.now()) {
      throw new HttpsError(
        "invalid-argument",
        "scheduledAt must be in the future."
      );
    }

    const ref = await db.collection("notification_campaigns").add({
      title,
      message,
      topic: kind === "topic" ? topic : "",
      targetUserId: kind === "single" ? targetUserId : "",
      kind,
      imageUrl,
      deepLink,
      redirectType,
      ctaLabel,
      soundType,
      targetAudience: str(data.targetAudience || data.targetType || topic),
      status: "scheduled",
      scheduledAt,
      createdAt: FieldValue.serverTimestamp(),
      sentCount: 0,
      failedCount: 0,
      openedCount: 0,
    });

    return { success: true, ok: true, campaignId: ref.id, status: "scheduled" };
  }
);

export const recordNotificationOpen = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
    const logId = str((request.data || {}).logId);
    if (!logId) {
      throw new HttpsError("invalid-argument", "logId is required.");
    }
    const logRef = db.collection("notification_logs").doc(logId);
    const snap = await logRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Notification log not found.");
    }
    await logRef.update({
      openedCount: FieldValue.increment(1),
      lastOpenedAt: FieldValue.serverTimestamp(),
      lastOpenedBy: uid,
    });
    return { success: true, ok: true };
  }
);

async function processScheduledCampaign(
  doc: QueryDocumentSnapshot
): Promise<void> {
  const d = doc.data();
  const kind = str(d.kind || "topic") === "single" ? "single" : "topic";
  const title = str(d.title);
  const message = str(d.message);
  const imageUrl = str(d.imageUrl);
  const deepLink = str(d.deepLink);
  const redirectType = str(d.redirectType);
  const ctaLabel = str(d.ctaLabel);
  const soundType = str(d.soundType);

  if (kind === "single") {
    const userId = str(d.targetUserId);
    const cust = await db.collection("customers").doc(userId).get();
    if (!cust.exists) {
      await doc.ref.update({
        status: "failed",
        failedCount: FieldValue.increment(1),
        lastError: "Customer not found",
      });
      return;
    }
    const c = cust.data() || {};
    const token = str(c.fcmToken || c.fcm_token);
    if (!token) {
      await doc.ref.update({
        status: "failed",
        failedCount: FieldValue.increment(1),
        lastError: "No FCM token",
      });
      return;
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
      campaignId: doc.id,
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
      await doc.ref.update({
        status: "completed",
        sentCount: FieldValue.increment(1),
        completedAt: FieldValue.serverTimestamp(),
      });
    } catch (e: unknown) {
      const err = e as { message?: string };
      await logRef.update({ status: "failed", error: err.message || String(e) });
      await doc.ref.update({
        status: "failed",
        failedCount: FieldValue.increment(1),
        lastError: err.message || String(e),
      });
    }
    return;
  }

  const topic = resolveTopic(d as Record<string, unknown>);
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
    campaignId: doc.id,
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
      campaignId: doc.id,
    });
    await logRef.update({
      status: "sent",
      messageId,
      sentAt: FieldValue.serverTimestamp(),
    });
    await doc.ref.update({
      status: "completed",
      sentCount: FieldValue.increment(1),
      completedAt: FieldValue.serverTimestamp(),
    });
  } catch (e: unknown) {
    const err = e as { message?: string };
    await logRef.update({ status: "failed", error: err.message || String(e) });
    await doc.ref.update({
      status: "failed",
      failedCount: FieldValue.increment(1),
      lastError: err.message || String(e),
    });
  }
}

export const notificationCampaignWorker = onSchedule(
  { region: REGION, schedule: "every 2 minutes" },
  async () => {
    const now = Date.now();
    const q = await db
      .collection("notification_campaigns")
      .where("status", "==", "scheduled")
      .limit(25)
      .get();

    for (const doc of q.docs) {
      const at = doc.data().scheduledAt as Timestamp | undefined;
      if (!at || at.toMillis() > now) continue;
      try {
        await doc.ref.update({ status: "processing" });
        await processScheduledCampaign(doc);
      } catch (e) {
        logger.error("notificationCampaignWorker", doc.id, e);
        try {
          await doc.ref.update({
            status: "failed",
            lastError: String(e),
          });
        } catch (_) {
          /* ignore */
        }
      }
    }
  }
);
