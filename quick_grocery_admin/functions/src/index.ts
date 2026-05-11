/**
 * SMS — Twilio keys only in Cloud Functions runtime (env / secrets).
 * Set: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER
 * Optional: DEFAULT_SMS_COUNTRY_CODE=91
 *
 * Admin claims: deploy `setAdminClaims` and set ADMIN_BOOTSTRAP_SECRET (12+ chars)
 * for first-time self-elevation from the Flutter SMS lock screen.
 *
 * Admin access: see `roles.ts` (admin, smsAdmin, superAdmin, role, …).
 */
import * as admin from "firebase-admin";
import { isBootstrapPanelEmail } from "./bootstrap_emails";
import { hasSmsPanelAccess } from "./roles";
export { setAdminClaims } from "./set_admin_claims";
export { syncAdminClaimsFromAdmins } from "./sync_admin_claims_from_admins";
import {
  FieldPath,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import twilio from "twilio";

admin.initializeApp();
const db = admin.firestore();

const REGION = "us-central1";
const BATCH_SIZE = 15;
const PROVIDER = "Twilio";
const CUSTOMER_PAGE = 100;

function emailVariantsForAdmins(email: string): string[] {
  const t = email.trim();
  const l = t.toLowerCase();
  return [...new Set([email, t, l])];
}

async function userEmailInAdminsTable(email: string | undefined): Promise<boolean> {
  if (!email) return false;
  for (const v of emailVariantsForAdmins(email)) {
    const snap = await db.collection("admins").where("email", "==", v).limit(1).get();
    if (!snap.empty) return true;
  }
  return false;
}

function getTwilioConfig() {
  const sid =
    process.env.TWILIO_ACCOUNT_SID ||
    process.env.twilio_account_sid ||
    "";
  const token =
    process.env.TWILIO_AUTH_TOKEN || process.env.twilio_auth_token || "";
  const from =
    process.env.TWILIO_FROM_NUMBER ||
    process.env.twilio_from_number ||
    "";
  return { sid, token, from };
}

async function assertSmsAdmin(uid: string | undefined) {
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const user = await admin.auth().getUser(uid);
  const c = (user.customClaims || {}) as Record<string, unknown>;
  if (hasSmsPanelAccess(c)) return;
  if (await userEmailInAdminsTable(user.email)) return;
  if (isBootstrapPanelEmail(user.email)) return;
  throw new HttpsError(
    "permission-denied",
    "SMS requires admin claims, an `admins` row, or BOOTSTRAP_ADMIN_EMAILS match."
  );
}

function normalizePhone(raw: string, defaultCc: string): string {
  const p = (raw || "").trim().replace(/\s+/g, "");
  if (!p) return "";
  if (p.startsWith("+")) return p;
  const digits = p.replace(/\D/g, "");
  if (digits.length === 10 && defaultCc === "91") return `+91${digits}`;
  if (digits.length >= 10) return `+${digits}`;
  return `+${digits}`;
}

async function logSms(entry: {
  userId: string;
  phone: string;
  message: string;
  status: string;
  provider: string;
  title?: string;
  campaignId?: string;
  error?: string;
}) {
  await db.collection("sms_logs").add({
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}

function matchesTarget(
  data: FirebaseFirestore.DocumentData,
  targetType: string,
  now: Date
): boolean {
  const phone = String(data.phone || "").trim();
  if (!phone) return false;
  if (targetType === "all_users") return true;
  if (targetType === "active_users") return data.is_blocked !== true;
  if (targetType === "new_users") {
    const ts = data.created_at as Timestamp | undefined;
    if (ts?.toDate) {
      return now.getTime() - ts.toDate().getTime() < 30 * 24 * 60 * 60 * 1000;
    }
    const s = String(data.created_date || "");
    if (!s) return true;
    const t = Date.parse(s);
    if (Number.isNaN(t)) return true;
    return now.getTime() - t < 30 * 24 * 60 * 60 * 1000;
  }
  return true;
}

async function sendTwilioMessage(to: string, body: string) {
  const { sid, token, from } = getTwilioConfig();
  if (!sid || !token || !from) {
    throw new HttpsError(
      "failed-precondition",
      "Twilio is not configured (TWILIO_* env vars)."
    );
  }
  const client = twilio(sid, token);
  return client.messages.create({ to, from, body });
}

export const sendSingleSMS = onCall({ region: REGION }, async (request) => {
  await assertSmsAdmin(request.auth?.uid);
  const phoneIn = String(request.data?.phone || "");
  const message = String(request.data?.message || "");
  const userId = request.data?.userId ? String(request.data.userId) : "";
  const title = request.data?.title ? String(request.data.title) : undefined;
  if (!phoneIn || !message) {
    throw new HttpsError("invalid-argument", "phone and message are required.");
  }
  const defaultCc = process.env.DEFAULT_SMS_COUNTRY_CODE || "91";
  const phone = normalizePhone(phoneIn, defaultCc);

  let body = message;
  if (userId) {
    const snap = await db.collection("customers").doc(userId).get();
    const name = String(snap.data()?.name || "there");
    body = body.replace(/\{\{userName\}\}/gi, name);
  } else {
    body = body.replace(/\{\{userName\}\}/gi, "there");
  }
  body = body.replace(/\{\{orderId\}\}/gi, "—");

  try {
    await sendTwilioMessage(phone, body);
    await logSms({
      userId: userId || "",
      phone,
      message: body,
      status: "sent",
      provider: PROVIDER,
      title,
    });
    return { ok: true, phone };
  } catch (e: unknown) {
    const err = e as { message?: string };
    await logSms({
      userId: userId || "",
      phone,
      message: body,
      status: "failed",
      provider: PROVIDER,
      title,
      error: err.message || String(e),
    });
    throw new HttpsError("internal", err.message || "SMS send failed");
  }
});

export const enqueueBroadcastSMS = onCall({ region: REGION }, async (request) => {
  await assertSmsAdmin(request.auth?.uid);
  const title = String(request.data?.title || "");
  const message = String(request.data?.message || "");
  const targetType = String(request.data?.targetType || "all_users");
  const scheduledIso = request.data?.scheduledAt
    ? String(request.data.scheduledAt)
    : "";
  if (!title || !message) {
    throw new HttpsError("invalid-argument", "title and message are required.");
  }

  const scheduledAt = scheduledIso
    ? Timestamp.fromDate(new Date(scheduledIso))
    : null;
  const now = Timestamp.now();
  const status =
    scheduledAt && scheduledAt.toMillis() > now.toMillis()
      ? "scheduled"
      : "queued";

  const ref = await db.collection("sms_campaigns").add({
    title,
    message,
    targetType,
    status,
    createdAt: FieldValue.serverTimestamp(),
    sentCount: 0,
    failedCount: 0,
    scheduledAt: scheduledAt || null,
    lastCustomerDocId: null,
    totalTargets: null,
  });

  return { ok: true, campaignId: ref.id, status };
});

/** Same as enqueue but requires a future [scheduledAt] (dedicated callable name). */
export const scheduleSMS = onCall({ region: REGION }, async (request) => {
  await assertSmsAdmin(request.auth?.uid);
  const title = String(request.data?.title || "");
  const message = String(request.data?.message || "");
  const targetType = String(request.data?.targetType || "all_users");
  const scheduledIso = String(request.data?.scheduledAt || "");
  if (!title || !message || !scheduledIso) {
    throw new HttpsError(
      "invalid-argument",
      "title, message, and scheduledAt are required."
    );
  }
  const scheduledAt = Timestamp.fromDate(new Date(scheduledIso));
  const now = Timestamp.now();
  if (scheduledAt.toMillis() <= now.toMillis()) {
    throw new HttpsError(
      "invalid-argument",
      "scheduledAt must be in the future."
    );
  }
  const ref = await db.collection("sms_campaigns").add({
    title,
    message,
    targetType,
    status: "scheduled",
    createdAt: FieldValue.serverTimestamp(),
    sentCount: 0,
    failedCount: 0,
    scheduledAt,
    lastCustomerDocId: null,
    totalTargets: null,
  });
  return { ok: true, campaignId: ref.id, status: "scheduled" };
});

export async function processCampaignBatch(
  campaignId: string,
  opts: { maxBatches?: number } = {}
): Promise<{
  campaignId: string;
  sent: number;
  failed: number;
  status: string;
  done: boolean;
}> {
  const maxBatches = opts.maxBatches ?? 1;
  const cref = db.collection("sms_campaigns").doc(campaignId);
  let totalSent = 0;
  let totalFailed = 0;

  for (let b = 0; b < maxBatches; b++) {
    const cdoc = await cref.get();
    if (!cdoc.exists) {
      throw new HttpsError("not-found", "Campaign not found.");
    }
    const c = cdoc.data()!;
    let status = String(c.status || "pending");

    if (status === "scheduled" && c.scheduledAt) {
      const when = (c.scheduledAt as Timestamp).toDate();
      if (when.getTime() > Date.now()) {
        const fresh = await cref.get();
        return {
          campaignId,
          sent: totalSent,
          failed: totalFailed,
          status: String(fresh.data()?.status || status),
          done: false,
        };
      }
      await cref.update({ status: "queued" });
      status = "queued";
    }

    if (status === "completed" || status === "cancelled") {
      return {
        campaignId,
        sent: totalSent,
        failed: totalFailed,
        status,
        done: true,
      };
    }

    const targetType = String(c.targetType || "all_users");
    const messageTemplate = String(c.message || "");
    const title = String(c.title || "");
    const lastId = c.lastCustomerDocId ? String(c.lastCustomerDocId) : null;

    let q = db
      .collection("customers")
      .orderBy(FieldPath.documentId())
      .limit(CUSTOMER_PAGE);
    if (lastId) {
      const lastSnap = await db.collection("customers").doc(lastId).get();
      if (lastSnap.exists) q = q.startAfter(lastSnap);
    }
    const snap = await q.get();

    if (snap.empty) {
      await cref.update({ status: "completed", lastCustomerDocId: null });
      const fresh = await cref.get();
      return {
        campaignId,
        sent: totalSent,
        failed: totalFailed,
        status: String(fresh.data()?.status || "completed"),
        done: true,
      };
    }

    const now = new Date();
    let attempts = 0;
    let lastScannedId: string | null = null;
    let batchSent = 0;
    let batchFail = 0;

    for (const doc of snap.docs) {
      lastScannedId = doc.id;
      const data = doc.data();
      if (!matchesTarget(data, targetType, now)) continue;

      const phone = normalizePhone(
        String(data.phone || ""),
        process.env.DEFAULT_SMS_COUNTRY_CODE || "91"
      );
      if (!phone.startsWith("+")) continue;

      if (attempts >= BATCH_SIZE) break;

      const name = String(data.name || "there");
      const body = messageTemplate
        .replace(/\{\{userName\}\}/gi, name)
        .replace(/\{\{userId\}\}/gi, doc.id)
        .replace(/\{\{orderId\}\}/gi, "—");

      try {
        await sendTwilioMessage(phone, body);
        await logSms({
          userId: doc.id,
          phone,
          message: body,
          status: "sent",
          provider: PROVIDER,
          title,
          campaignId,
        });
        batchSent++;
        attempts++;
      } catch (e: unknown) {
        const err = e as { message?: string };
        await logSms({
          userId: doc.id,
          phone,
          message: body,
          status: "failed",
          provider: PROVIDER,
          title,
          campaignId,
          error: err.message || String(e),
        });
        batchFail++;
        attempts++;
      }
    }

    await cref.update({
      sentCount: FieldValue.increment(batchSent),
      failedCount: FieldValue.increment(batchFail),
      lastCustomerDocId: lastScannedId,
      status: "processing",
    });
    totalSent += batchSent;
    totalFailed += batchFail;

    const endOfList = snap.docs.length < CUSTOMER_PAGE;
    if (endOfList) {
      await cref.update({ status: "completed", lastCustomerDocId: null });
      const fresh = await cref.get();
      return {
        campaignId,
        sent: totalSent,
        failed: totalFailed,
        status: String(fresh.data()?.status || "completed"),
        done: true,
      };
    }
  }

  const fresh = await cref.get();
  return {
    campaignId,
    sent: totalSent,
    failed: totalFailed,
    status: String(fresh.data()?.status || "processing"),
    done: false,
  };
}

export const resumeBroadcastSMS = onCall({ region: REGION }, async (request) => {
  await assertSmsAdmin(request.auth?.uid);
  const campaignId = String(request.data?.campaignId || "");
  if (!campaignId) {
    throw new HttpsError("invalid-argument", "campaignId is required.");
  }
  return processCampaignBatch(campaignId, { maxBatches: 4 });
});

export const retryFailedSMS = onCall({ region: REGION }, async (request) => {
  await assertSmsAdmin(request.auth?.uid);
  const max = Math.min(Number(request.data?.max || 20), 50);
  const q = await db
    .collection("sms_logs")
    .where("status", "==", "failed")
    .limit(max)
    .get();

  let retried = 0;
  for (const doc of q.docs) {
    if (doc.data().retryResolved === true) continue;
    const d = doc.data();
    const phone = String(d.phone || "");
    const message = String(d.message || "");
    if (!phone || !message) continue;
    try {
      await sendTwilioMessage(phone, message);
      await logSms({
        userId: String(d.userId || ""),
        phone,
        message,
        status: "sent",
        provider: PROVIDER,
        title: d.title ? String(d.title) : undefined,
        campaignId: d.campaignId ? String(d.campaignId) : undefined,
      });
      await doc.ref.update({ retryResolved: true });
      retried++;
    } catch (e: unknown) {
      logger.warn("retryFailedSMS skip", e);
    }
  }
  return { ok: true, retried };
});

export const smsCampaignWorker = onSchedule(
  { region: REGION, schedule: "every 3 minutes" },
  async () => {
    const now = Timestamp.now();
    const due = await db
      .collection("sms_campaigns")
      .where("status", "==", "scheduled")
      .where("scheduledAt", "<=", now)
      .limit(5)
      .get();
    for (const d of due.docs) {
      await d.ref.update({ status: "queued" });
    }

    const active = await db
      .collection("sms_campaigns")
      .where("status", "in", ["queued", "processing"])
      .limit(3)
      .get();

    for (const d of active.docs) {
      try {
        await processCampaignBatch(d.id, { maxBatches: 2 });
      } catch (e) {
        logger.error("smsCampaignWorker", d.id, e);
      }
    }
  }
);
