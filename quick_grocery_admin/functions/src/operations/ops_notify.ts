import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const db = admin.firestore();

export type OpsCategory =
  | "orders"
  | "users"
  | "vendors"
  | "payments"
  | "stock"
  | "delivery"
  | "system"
  | "security"
  | "promotions";

export type OpsNotificationType =
  | "new_order"
  | "order_accepted"
  | "order_cancelled"
  | "order_delayed"
  | "order_delivered"
  | "cod_received"
  | "payment_success"
  | "payment_failed"
  | "payment_received"
  | "payment_released"
  | "refund_request"
  | "withdrawal_request"
  | "user_registered"
  | "vendor_registered"
  | "vendor_request"
  | "vendor_approval"
  | "vendor_approved"
  | "vendor_rejected"
  | "delivery_registered"
  | "delivery_assigned"
  | "delivery_completed"
  | "driver_assigned"
  | "driver_rejected"
  | "driver_offline"
  | "delivery_delayed"
  | "low_stock"
  | "stock_low"
  | "out_of_stock"
  | "coupon_used"
  | "abandoned_cart"
  | "daily_summary"
  | "system_update"
  | "security_alert"
  | "password_reset_requested"
  | "password_reset_completed"
  | "failed_login_spike"
  | "fraud_alert"
  | "system_error";

export type OpsPriority = "low" | "normal" | "high" | "urgent";

function soundTypeForCategory(category: OpsCategory): string {
  switch (category) {
    case "users":
      return "users";
    case "vendors":
      return "vendors";
    case "payments":
      return "payments";
    case "stock":
      return "stock";
    case "delivery":
      return "delivery";
    case "security":
      return "security";
    case "promotions":
      return "promotions";
    default:
      return "orders";
  }
}

function priorityForType(type: OpsNotificationType): OpsPriority {
  if (
    type === "payment_failed" ||
    type === "fraud_alert" ||
    type === "system_error" ||
    type === "out_of_stock"
  ) {
    return "urgent";
  }
  if (
    type === "new_order" ||
    type === "order_cancelled" ||
    type === "low_stock" ||
    type === "failed_login_spike"
  ) {
    return "high";
  }
  return "normal";
}

export function str(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

export function num(v: unknown): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function buildDataPayload(parts: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const [k, v] of Object.entries(parts)) {
    out[k] = v ?? "";
  }
  out.click_action = "FLUTTER_NOTIFICATION_CLICK";
  return out;
}

function sourceAppForCategory(category: OpsCategory): string {
  switch (category) {
    case "users":
      return "user_app";
    case "vendors":
      return "vendor_app";
    case "delivery":
      return "delivery_app";
    default:
      return "system";
  }
}

/** In-app admin feed — real-time bell + history. */
export async function writeAdminNotification(opts: {
  title: string;
  message: string;
  type: OpsNotificationType;
  category: OpsCategory;
  metadata?: Record<string, unknown>;
  targetAdminId?: string;
  soundAlert?: boolean;
  priority?: OpsPriority;
  sticky?: boolean;
  sourceApp?: string;
}): Promise<string> {
  const priority = opts.priority ?? priorityForType(opts.type);
  const soundType = soundTypeForCategory(opts.category);
  const sourceApp = opts.sourceApp ?? sourceAppForCategory(opts.category);
  const meta = opts.metadata || {};
  const payload = {
    title: opts.title,
    message: opts.message,
    type: opts.type,
    category: opts.category,
    notification_type: opts.type,
    notification_title: opts.title,
    notification_message: opts.message,
    read: false,
    is_read: false,
    isRead: false,
    soundAlert: opts.soundAlert ?? (priority === "high" || priority === "urgent"),
    sound_type: soundType,
    priority,
    priority_level: priority,
    sticky: opts.sticky === true,
    targetAdminId: opts.targetAdminId || "",
    target: "admin",
    sourceApp,
    metadata: meta,
    data: meta,
    createdAt: FieldValue.serverTimestamp(),
    created_at: FieldValue.serverTimestamp(),
  };

  const ref = await db.collection("admin_notifications").add(payload);
  await db.collection("notifications").doc(ref.id).set(payload);
  return ref.id;
}

export async function writeActivityLog(opts: {
  action: string;
  entityType: string;
  entityId: string;
  summary: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  await db.collection("activity_logs").add({
    action: opts.action,
    entityType: opts.entityType,
    entityId: opts.entityId,
    summary: opts.summary,
    metadata: opts.metadata || {},
    createdAt: FieldValue.serverTimestamp(),
  });
}

export async function writeUserInbox(
  uid: string,
  opts: {
    title: string;
    body: string;
    type: string;
    targetId?: string;
    deepLink?: string;
  }
): Promise<void> {
  await db
    .collection("notifications")
    .doc(uid)
    .collection("items")
    .add({
      title: opts.title,
      body: opts.body,
      type: opts.type,
      targetId: opts.targetId || "",
      deepLink: opts.deepLink || "",
      imageUrl: "",
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
}

export async function sendPushToToken(opts: {
  token: string;
  title: string;
  body: string;
  soundType?: string;
  deepLink?: string;
  redirectType?: string;
}): Promise<string | null> {
  if (!opts.token) return null;
  const data = buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink || "",
    redirectType: opts.redirectType || "system",
    soundType: opts.soundType || "orders",
  });
  try {
    return await admin.messaging().send({
      token: opts.token,
      notification: { title: opts.title, body: opts.body },
      data,
    });
  } catch (e) {
    console.warn("[ops] FCM token send failed:", e);
    return null;
  }
}

export async function sendPushToTopic(opts: {
  topic: string;
  title: string;
  body: string;
  soundType?: string;
  deepLink?: string;
  redirectType?: string;
}): Promise<string | null> {
  const data = buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink || "",
    redirectType: opts.redirectType || "system",
    soundType: opts.soundType || "orders",
  });
  try {
    return await admin.messaging().send({
      topic: opts.topic,
      notification: { title: opts.title, body: opts.body },
      data,
    });
  } catch (e) {
    console.warn("[ops] FCM topic send failed:", e);
    return null;
  }
}

/** Notify all admins with stored FCM tokens + admin_ops topic. */
export async function notifyAdmins(opts: {
  title: string;
  message: string;
  type: OpsNotificationType;
  category: OpsCategory;
  metadata?: Record<string, unknown>;
  soundAlert?: boolean;
}): Promise<void> {
  await writeAdminNotification({
    title: opts.title,
    message: opts.message,
    type: opts.type,
    category: opts.category,
    metadata: opts.metadata,
    soundAlert: opts.soundAlert,
  });
  await writeActivityLog({
    action: opts.type,
    entityType: opts.category,
    entityId: str(opts.metadata?.orderId || opts.metadata?.userId || ""),
    summary: opts.message,
    metadata: opts.metadata,
  });
  const soundType = soundTypeForCategory(opts.category);
  await sendPushToTopic({
    topic: "admin_ops",
    title: opts.title,
    body: opts.message,
    soundType,
    deepLink: str(opts.metadata?.deepLink || "/orders"),
  });
  const admins = await db.collection("admins").get();
  for (const doc of admins.docs) {
    const token = str(doc.data().fcmToken || doc.data().fcm_token);
    if (token) {
      await sendPushToToken({
        token,
        title: opts.title,
        body: opts.message,
        soundType,
      });
    }
  }
}

/** Callable test hook — writes a sample notification (deploy functions). */
export async function seedTestAdminNotification(): Promise<string> {
  return writeAdminNotification({
    title: "Test notification",
    message: "Real-time admin notification system is connected.",
    type: "daily_summary",
    category: "system",
    soundAlert: true,
    priority: "normal",
    metadata: { test: true },
  });
}

export async function getOpsSettings(): Promise<Record<string, unknown>> {
  const snap = await db.collection("settings").doc("ops_settings").get();
  const d = snap.data() || {};
  return {
    lowStockThreshold: num(d.lowStockThreshold) || 10,
    autoDisableOutOfStock: d.autoDisableOutOfStock !== false,
    abandonedCartDelayHours: num(d.abandonedCartDelayHours) || 24,
    abandonedCartEnabled: d.abandonedCartEnabled !== false,
    autoAssignDriver: d.autoAssignDriver !== false,
    adminSoundEnabled: d.adminSoundEnabled !== false,
  };
}

export function vendorTopic(vendorId: string): string {
  const s = vendorId.trim().toLowerCase().replace(/[^a-z0-9\-_.~%]/g, "_");
  return `vendor_${s || "unknown"}`;
}

export function deliveryTopic(riderId: string): string {
  const s = riderId.trim().toLowerCase().replace(/[^a-z0-9\-_.~%]/g, "_");
  return `delivery_${s || "unknown"}`;
}

export async function notifyVendor(
  vendorId: string,
  opts: {
    title: string;
    message: string;
    type: OpsNotificationType;
    metadata?: Record<string, unknown>;
  }
): Promise<void> {
  const topic = vendorTopic(vendorId);
  await sendPushToTopic({
    topic,
    title: opts.title,
    body: opts.message,
    soundType: "orders",
  });
  const v = await db.collection("vendors").doc(vendorId).get();
  const token = str(v.data()?.fcmToken || v.data()?.fcm_token);
  if (token) {
    await sendPushToToken({
      token,
      title: opts.title,
      body: opts.message,
      soundType: "orders",
    });
  }
}

export async function notifyDeliveryRider(
  riderId: string,
  opts: { title: string; message: string; metadata?: Record<string, unknown> }
): Promise<void> {
  const topic = deliveryTopic(riderId);
  await sendPushToTopic({
    topic,
    title: opts.title,
    body: opts.message,
    soundType: "delivery",
  });
  const r = await db.collection("delivery_boys").doc(riderId).get();
  const token = str(r.data()?.fcmToken || r.data()?.fcm_token);
  if (token) {
    await sendPushToToken({
      token,
      title: opts.title,
      body: opts.message,
      soundType: "delivery",
    });
  }
}

export async function appendDeliveryTracking(
  orderId: string,
  event: string,
  detail: Record<string, unknown>
): Promise<void> {
  await db
    .collection("delivery_tracking")
    .doc(orderId)
    .collection("events")
    .add({
      event,
      detail,
      createdAt: FieldValue.serverTimestamp(),
    });
}
