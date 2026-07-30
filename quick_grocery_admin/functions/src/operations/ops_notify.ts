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
  | "driver_accepted"
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
  if (!out.timestamp) {
    out.timestamp = String(Date.now());
  }
  return out;
}

/** Data-only FCM — app shows exactly one tray entry via flutter_local_notifications. */
function buildOpsPushData(
  parts: Record<string, string>,
  title: string,
  body: string,
): Record<string, string> {
  return buildDataPayload({
    ...parts,
    displayMode: "data_only",
    title,
    body,
    message: body,
  });
}

function apnsSoundForChannel(soundType?: string): string {
  if (soundType === "delivery") return "delivery_alert.mp3";
  return "new_order.mp3";
}

/** Stable id: one push per order + type + recipient (retry-safe). */
export function buildEventId(
  orderId: string,
  type: string,
  receiver: string,
): string {
  const oid = orderId || "na";
  return `${oid}:${type}:${receiver}`;
}

function isAlreadyExistsError(err: unknown): boolean {
  const code = (err as { code?: number | string })?.code;
  return code === 6 || code === "already-exists" || code === "ALREADY_EXISTS";
}

/** Returns false when this event was already sent (Cloud Function retry safe). */
async function claimNotificationEvent(eventId: string): Promise<boolean> {
  const safeId = eventId.replace(/\//g, "_").slice(0, 500);
  const ref = db.collection("notification_event_dedupe").doc(safeId);
  try {
    await ref.create({
      eventId: safeId,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log(`[ops] notification event claimed eventId=${safeId}`);
    return true;
  } catch (err) {
    if (isAlreadyExistsError(err)) {
      console.log(`[ops] notification event duplicate skipped eventId=${safeId}`);
      return false;
    }
    throw err;
  }
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

/** Global notification feed for cross-app audit + admin realtime listener. */
export async function writeGlobalNotification(opts: {
  type: string;
  orderId?: string;
  customerName?: string;
  customerPhone?: string;
  vendorId?: string;
  deliveryBoyId?: string;
  cancelledBy?: string;
  title: string;
  body: string;
  sender?: string;
  receiver?: string;
  amount?: number;
  metadata?: Record<string, unknown>;
}): Promise<string> {
  const ref = await db.collection("global_notifications").add({
    type: opts.type,
    orderId: str(opts.orderId),
    customerName: str(opts.customerName),
    customerPhone: str(opts.customerPhone),
    vendorId: str(opts.vendorId),
    deliveryBoyId: str(opts.deliveryBoyId),
    cancelledBy: str(opts.cancelledBy),
    title: opts.title,
    body: opts.body,
    message: opts.body,
    sender: str(opts.sender || "system"),
    receiver: str(opts.receiver || "all"),
    amount: num(opts.amount),
    metadata: opts.metadata || {},
    read: false,
    timestamp: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}

/** Audit trail for every push/in-app notification. */
export async function writeNotificationLog(opts: {
  type: string;
  sender: string;
  receiver: string;
  orderId?: string;
  title?: string;
  body?: string;
  channel?: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  await db.collection("notification_logs").add({
    type: opts.type,
    sender: opts.sender,
    receiver: opts.receiver,
    orderId: str(opts.orderId),
    title: str(opts.title),
    body: str(opts.body),
    channel: str(opts.channel || "fcm"),
    metadata: opts.metadata || {},
    timestamp: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(),
  });
}

function androidNotificationConfig(soundType?: string): {
  channelId: string;
  sound: string;
} {
  if (soundType === "delivery") {
    return { channelId: "delivery_assignments", sound: "delivery_alert" };
  }
  return { channelId: "vendor_orders", sound: "new_order" };
}

export async function sendPushToToken(opts: {
  token: string;
  title: string;
  body: string;
  soundType?: string;
  deepLink?: string;
  redirectType?: string;
  data?: Record<string, string>;
  eventId?: string;
}): Promise<string | null> {
  if (!opts.token) return null;
  const eventId = opts.eventId || opts.data?.eventId || "";
  if (eventId && !(await claimNotificationEvent(eventId))) {
    return null;
  }
  const data = opts.data ?? buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink || "",
    redirectType: opts.redirectType || "system",
    soundType: opts.soundType || "orders",
    eventId,
  });
  if (eventId && !data.eventId) {
    data.eventId = eventId;
  }
  try {
    const android = androidNotificationConfig(opts.soundType);
    const pushData = buildOpsPushData(
      { ...data, channelId: android.channelId, sound: android.sound },
      opts.title,
      opts.body,
    );
    console.log(
      `[FCM:SEND] token receiver=token eventId=${eventId || "—"} ` +
        `type=${data.type || "—"} orderId=${data.orderId || "—"}`,
    );
    const id = await admin.messaging().send({
      token: opts.token,
      data: pushData,
      android: { priority: "high" },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            "content-available": 1,
            sound: apnsSoundForChannel(opts.soundType),
            badge: 1,
          },
        },
      },
    });
    console.log(`[FCM:SENT] token messageId=${id} eventId=${eventId || "—"}`);
    return id;
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
  data?: Record<string, string>;
  eventId?: string;
}): Promise<string | null> {
  const eventId = opts.eventId || opts.data?.eventId || "";
  if (eventId && !(await claimNotificationEvent(eventId))) {
    return null;
  }
  const data = opts.data ?? buildDataPayload({
    title: opts.title,
    message: opts.body,
    deepLink: opts.deepLink || "",
    redirectType: opts.redirectType || "system",
    soundType: opts.soundType || "orders",
    eventId,
  });
  if (eventId && !data.eventId) {
    data.eventId = eventId;
  }
  try {
    const android = androidNotificationConfig(opts.soundType);
    const pushData = buildOpsPushData(
      { ...data, channelId: android.channelId, sound: android.sound },
      opts.title,
      opts.body,
    );
    console.log(
      `[FCM:SEND] topic=${opts.topic} eventId=${eventId || "—"} ` +
        `type=${data.type || "—"} orderId=${data.orderId || "—"}`,
    );
    const id = await admin.messaging().send({
      topic: opts.topic,
      data: pushData,
      android: { priority: "high" },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            "content-available": 1,
            sound: apnsSoundForChannel(opts.soundType),
            badge: 1,
          },
        },
      },
    });
    console.log(
      `[FCM:SENT] topic=${opts.topic} messageId=${id} eventId=${eventId || "—"}`,
    );
    return id;
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
  await writeNotificationLog({
    type: opts.type,
    sender: "cloud_function",
    receiver: "admin",
    orderId: str(opts.metadata?.orderId),
    title: opts.title,
    body: opts.message,
    channel: "firestore+activity",
  });
  await writeActivityLog({
    action: opts.type,
    entityType: opts.category,
    entityId: str(opts.metadata?.orderId || opts.metadata?.userId || ""),
    summary: opts.message,
    metadata: opts.metadata,
  });
  const soundType = soundTypeForCategory(opts.category);
  const orderId = str(opts.metadata?.orderId);
  const eventId = buildEventId(orderId, opts.type, "admin_ops");
  // Topic only — avoid duplicate when admin devices also store a direct token.
  await sendPushToTopic({
    topic: "admin_ops",
    title: opts.title,
    body: opts.message,
    soundType,
    deepLink: str(opts.metadata?.deepLink || "/orders"),
    eventId,
    data: buildDataPayload({
      type: opts.type,
      orderId,
      title: opts.title,
      message: opts.message,
      deepLink: str(opts.metadata?.deepLink || "/orders"),
      redirectType: "admin",
      soundType,
      eventId,
    }),
  });
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
    assignRadiusKm: num(d.assignRadiusKm) || 8,
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
  const meta = opts.metadata || {};
  const orderId = str(meta.orderId);
  const customerName = str(meta.customerName);
  const amount = num(meta.amount);
  const title = opts.title;
  const body = opts.message;

  await db.collection("vendors").doc(vendorId).collection("notifications").add({
    title,
    body,
    type: opts.type,
    orderId,
    customerName,
    amount,
    read: false,
    source: "cloud_function",
    createdAt: FieldValue.serverTimestamp(),
  });

  const eventId = buildEventId(orderId, opts.type, `vendor:${vendorId}`);
  console.log(
    `[NOTIFY:START] notifyVendor vendorId=${vendorId} type=${opts.type} ` +
      `orderId=${orderId} eventId=${eventId}`,
  );
  const data = buildDataPayload({
    type: opts.type,
    orderId,
    customerName,
    amount: String(amount),
    title,
    message: body,
    deepLink: orderId ? `/orders/${orderId}` : "",
    redirectType: "order",
    targetScreen: vendorTargetScreen(opts.type),
    notificationType: opts.type,
    status: opts.type,
    soundType: "orders",
    eventId,
  });

  // Topic only — never also sendPushToToken for the same vendor (that produced
  // identical dual tray notifications: one via topic, one via device token).
  // claimNotificationEvent inside sendPushToTopic makes CF retries idempotent.
  const topic = vendorTopic(vendorId);
  const fcmMessageId = await sendPushToTopic({
    topic,
    title,
    body,
    soundType: "orders",
    data,
    eventId,
  });

  await writeNotificationLog({
    type: opts.type,
    sender: "cloud_function",
    receiver: `vendor:${vendorId}`,
    orderId,
    title,
    body,
    channel: "fcm+firestore",
    metadata: { eventId, topic, fcmMessageId: fcmMessageId || "" },
  });
  console.log(
    `[NOTIFY:END] notifyVendor vendorId=${vendorId} type=${opts.type} ` +
      `orderId=${orderId} eventId=${eventId} fcmMessageId=${fcmMessageId || "skipped"}`,
  );
}

export async function notifyDeliveryRider(
  riderId: string,
  opts: {
    title: string;
    message: string;
    type?: string;
    metadata?: Record<string, unknown>;
  }
): Promise<void> {
  if (!riderId) return;

  const orderId = str(opts.metadata?.orderId);
  const notifType = str(opts.type || "delivery_assigned");
  const title = opts.title;
  const body = opts.message;
  const eventId = buildEventId(orderId, notifType, `rider:${riderId}`);

  console.log(
    `[NOTIFY:START] notifyDeliveryRider riderId=${riderId} type=${notifType} ` +
      `orderId=${orderId} eventId=${eventId}`,
  );

  await db.collection("delivery_boys").doc(riderId).collection("notifications").add({
    title,
    body,
    type: notifType,
    orderId,
    eventId,
    read: false,
    source: "cloud_function",
    createdAt: FieldValue.serverTimestamp(),
  });

  const data = buildDataPayload({
    type: notifType,
    orderId,
    title,
    message: body,
    deepLink: orderId ? `/orders/${orderId}` : "",
    redirectType: "delivery_app",
    targetScreen: deliveryTargetScreen(notifType),
    notificationType: notifType,
    status: notifType,
    soundType: notifType === "order_cancelled" ? "orders" : "delivery",
    eventId,
  });

  // Topic only — never also sendPushToToken for the same rider (that produced
  // identical dual tray notifications: one via topic, one via device token).
  // Combined with client OS+local double-display that yielded 4 identical trays.
  // claimNotificationEvent inside sendPushToTopic makes CF retries idempotent.
  const topic = deliveryTopic(riderId);
  const fcmMessageId = await sendPushToTopic({
    topic,
    title,
    body,
    soundType: notifType === "order_cancelled" ? "orders" : "delivery",
    data,
    eventId,
  });

  await writeNotificationLog({
    type: notifType,
    sender: "cloud_function",
    receiver: `rider:${riderId}`,
    orderId,
    title,
    body,
    channel: "fcm+firestore",
    metadata: { eventId, topic, fcmMessageId: fcmMessageId || "" },
  });
  console.log(
    `[NOTIFY:END] notifyDeliveryRider riderId=${riderId} type=${notifType} ` +
      `orderId=${orderId} eventId=${eventId} fcmMessageId=${fcmMessageId || "skipped"}`,
  );
}

/** Maps ops notification `type` to client `targetScreen` for deep linking. */
export function customerTargetScreen(type: string): string {
  const t = str(type).toLowerCase();
  switch (t) {
    case "order_placed":
    case "order_accepted":
    case "order_packed":
    case "order_confirmed":
    case "payment_successful":
    case "payment_success":
      return "order_tracking";
    case "delivery_assigned":
    case "delivery_partner_assigned":
    case "driver_assigned":
      return "delivery_tracking";
    case "order_out_for_delivery":
    case "out_for_delivery":
      return "live_tracking";
    case "order_delivered":
    case "delivered":
      return "order_delivered";
    case "order_cancelled":
    case "cancelled":
    case "cancelled_by_vendor":
    case "cancelled_by_customer":
      return "order_cancelled";
    case "payment_failed":
      return "payment_retry";
    case "refund_initiated":
    case "refund":
      return "refund_details";
    default:
      return "order_tracking";
  }
}

/** Vendor app deep-link target for ops notification types. */
export function vendorTargetScreen(type: string): string {
  const t = str(type).toLowerCase();
  switch (t) {
    case "low_stock":
    case "stock_low":
    case "out_of_stock":
      return "products_tab";
    case "new_order":
    case "order_cancelled":
    case "order_delivered":
    case "driver_assigned":
    case "payment_released":
    case "payment_received":
    default:
      return "order_detail";
  }
}

/** Delivery app deep-link target for ops notification types. */
export function deliveryTargetScreen(type: string): string {
  const t = str(type).toLowerCase();
  switch (t) {
    case "delivery_assigned":
    case "driver_assigned":
      return "assignment";
    case "order_cancelled":
    case "cancelled":
      return "cancellation";
    case "delivery_tip":
      return "wallet_tab";
    case "delivery_completed":
    case "order_delivered":
    default:
      return "order_detail";
  }
}

/** Push + inbox for end customers (`customers/{uid}`). */
export async function notifyCustomer(
  uid: string,
  opts: {
    title: string;
    body: string;
    type?: string;
    deepLink?: string;
    orderId?: string;
    extraData?: Record<string, string>;
  }
): Promise<void> {
  if (!uid) return;

  await writeUserInbox(uid, {
    title: opts.title,
    body: opts.body,
    type: opts.type || "order",
    targetId: opts.orderId || "",
    deepLink: opts.deepLink || "",
  });

  const orderId = opts.orderId || "";
  const notifType = opts.type || "order";
  const deepLink = opts.deepLink || (orderId ? `/orders/${orderId}` : "");
  const targetScreen = customerTargetScreen(notifType);
  const eventId = buildEventId(orderId, notifType, `customer:${uid}`);
  const cust = await db.collection("customers").doc(uid).get();
  const token = str(cust.data()?.fcmToken || cust.data()?.fcm_token);
  if (token) {
    await sendPushToToken({
      token,
      title: opts.title,
      body: opts.body,
      soundType: "delivery",
      deepLink,
      redirectType: "order_page",
      eventId,
      data: buildDataPayload({
        type: notifType,
        notificationType: notifType,
        status: notifType,
        orderId,
        targetScreen,
        title: opts.title,
        message: opts.body,
        deepLink,
        redirectType: "order_page",
        soundType: "delivery",
        eventId,
        ...(opts.extraData || {}),
      }),
    });
  }

  await writeNotificationLog({
    type: opts.type || "order",
    sender: "cloud_function",
    receiver: `customer:${uid}`,
    orderId: opts.orderId,
    title: opts.title,
    body: opts.body,
    channel: "fcm+inbox",
  });
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
