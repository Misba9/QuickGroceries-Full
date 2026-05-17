import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import {
  appendDeliveryTracking,
  getOpsSettings,
  notifyAdmins,
  notifyDeliveryRider,
  notifyVendor,
  num,
  str,
  writeUserInbox,
} from "./ops_notify";

const db = admin.firestore();

function orderTotal(data: Record<string, unknown>): number {
  const bill = data.bill as Record<string, unknown> | undefined;
  if (bill && bill.total != null) return num(bill.total);
  const products = (data.products as unknown[]) || [];
  let sum = 0;
  for (const p of products) {
    const row = p as Record<string, unknown>;
    sum += num(row.price) * num(row.itemCount || 1);
  }
  return sum + num(data.delivery_charge);
}

function paymentLabel(data: Record<string, unknown>): string {
  const m = str(data.paymentMethod);
  if (m) return m.toUpperCase();
  return data.isPaid ? "PAID" : "COD";
}

function vendorIds(data: Record<string, unknown>): string[] {
  const products = (data.products as unknown[]) || [];
  const ids = new Set<string>();
  for (const p of products) {
    const row = p as Record<string, unknown>;
    const id = str(row.vendor_id || row.vendorId);
    if (id) ids.add(id);
  }
  return [...ids];
}

async function vendorNames(ids: string[]): Promise<string> {
  const names: string[] = [];
  for (const id of ids.slice(0, 5)) {
    const v = await db.collection("vendors").doc(id).get();
    if (v.exists) names.push(str(v.data()?.name || v.data()?.shopName || id));
  }
  return names.join(", ") || "—";
}

/** New order → admin + vendors. */
export const onOrderCreated = onDocumentCreated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const orderId = event.params.orderId;
    const data = snap.data() as Record<string, unknown>;
    const customer = str(data.customer_name || data.customerName);
    const total = orderTotal(data);
    const payment = paymentLabel(data);
    const vIds = vendorIds(data);
    const vName = await vendorNames(vIds);

    await notifyAdmins({
      title: "New order",
      message: `#${orderId.slice(-6)} · ${customer} · ₹${total.toFixed(0)} · ${payment}`,
      type: "new_order",
      category: "orders",
      soundAlert: true,
      metadata: {
        orderId,
        customerName: customer,
        amount: total,
        paymentType: payment,
        vendorName: vName,
        vendorIds: vIds,
        deepLink: `/orders/${orderId}`,
      },
    });

    for (const vendorId of vIds) {
      await notifyVendor(vendorId, {
        title: "New order",
        message: `Order #${orderId.slice(-6)} from ${customer} · ₹${total.toFixed(0)}`,
        type: "new_order",
        metadata: { orderId, customerName: customer, amount: total },
      });
    }

    const uid = str(data.uuid);
    if (uid) {
      await writeUserInbox(uid, {
        title: "Order placed",
        body: `We received your order #${orderId.slice(-6)}.`,
        type: "order",
        targetId: orderId,
        deepLink: `/orders/${orderId}`,
      });
    }

    const settings = await getOpsSettings();
    if (settings.autoAssignDriver) {
      await tryAutoAssignDriver(orderId, data);
    }
  }
);

/** Status changes → vendor, customer, delivery, tracking. */
export const onOrderUpdated = onDocumentUpdated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before.data() as Record<string, unknown> | undefined;
    const after = event.data?.after.data() as Record<string, unknown> | undefined;
    if (!before || !after) return;
    const orderId = event.params.orderId;
    const prevStatus = str(before.order_status || before.status);
    const nextStatus = str(after.order_status || after.status);
    const prevCancelled = Boolean(before.isCancelled);
    const nextCancelled = Boolean(after.isCancelled);
    const prevRider = str(before.deliveryBoyId);
    const nextRider = str(after.deliveryBoyId);
    const uid = str(after.uuid);

    if (nextStatus !== prevStatus) {
      await appendDeliveryTracking(orderId, "status_change", {
        from: prevStatus,
        to: nextStatus,
      });
    }

    if (nextCancelled && !prevCancelled) {
      await notifyAdmins({
        title: "Order cancelled",
        message: `Order #${orderId.slice(-6)} was cancelled.`,
        type: "order_cancelled",
        category: "orders",
        metadata: { orderId },
      });
      for (const vendorId of vendorIds(after)) {
        await notifyVendor(vendorId, {
          title: "Order cancelled",
          message: `Order #${orderId.slice(-6)} was cancelled.`,
          type: "order_cancelled",
          metadata: { orderId },
        });
      }
      if (uid) {
        await writeUserInbox(uid, {
          title: "Order cancelled",
          body: `Your order #${orderId.slice(-6)} was cancelled.`,
          type: "order",
          targetId: orderId,
        });
      }
    }

    if (
      nextStatus.toLowerCase().includes("delivered") &&
      !prevStatus.toLowerCase().includes("delivered")
    ) {
      await notifyAdmins({
        title: "Order delivered",
        message: `Order #${orderId.slice(-6)} marked delivered.`,
        type: "order_delivered",
        category: "delivery",
        metadata: { orderId },
      });
      for (const vendorId of vendorIds(after)) {
        await notifyVendor(vendorId, {
          title: "Order delivered",
          message: `Order #${orderId.slice(-6)} delivered.`,
          type: "order_delivered",
          metadata: { orderId },
        });
      }
      if (uid) {
        await writeUserInbox(uid, {
          title: "Delivered",
          body: `Your order #${orderId.slice(-6)} has been delivered.`,
          type: "delivery",
          targetId: orderId,
          deepLink: `/orders/${orderId}`,
        });
      }
    }

    if (nextRider && nextRider !== prevRider) {
      await notifyDeliveryRider(nextRider, {
        title: "New delivery assigned",
        message: `You have been assigned order #${orderId.slice(-6)}.`,
        metadata: { orderId },
      });
      await appendDeliveryTracking(orderId, "rider_assigned", {
        deliveryBoyId: nextRider,
      });
      await notifyAdmins({
        title: "Driver assigned",
        message: `Rider ${nextRider} assigned to #${orderId.slice(-6)}.`,
        type: "driver_assigned",
        category: "delivery",
        metadata: { orderId, deliveryBoyId: nextRider },
      });
    }

    const prevPaid = Boolean(before.isPaid);
    const nextPaid = Boolean(after.isPaid);
    if (nextPaid && !prevPaid) {
      const total = orderTotal(after);
      await notifyAdmins({
        title: "Payment received",
        message: `₹${total.toFixed(0)} for order #${orderId.slice(-6)}.`,
        type: "payment_success",
        category: "payments",
        soundAlert: true,
        metadata: { orderId, amount: total },
      });
      for (const vendorId of vendorIds(after)) {
        await notifyVendor(vendorId, {
          title: "Payment released",
          message: `Payment confirmed for order #${orderId.slice(-6)}.`,
          type: "payment_released",
          metadata: { orderId },
        });
      }
    }

    const prevFailed = str(before.payment_status || before.paymentStatus).toLowerCase();
    const nextFailed = str(after.payment_status || after.paymentStatus).toLowerCase();
    if (
      (nextFailed.includes("fail") || nextFailed.includes("declin")) &&
      !prevFailed.includes("fail")
    ) {
      await notifyAdmins({
        title: "Payment failed",
        message: `Payment failed for order #${orderId.slice(-6)}.`,
        type: "payment_failed",
        category: "payments",
        soundAlert: true,
        metadata: { orderId },
      });
    }

    const accepted = (s: string) =>
      s.toLowerCase().includes("accept") || s.toLowerCase().includes("prepar");
    if (accepted(nextStatus) && !accepted(prevStatus)) {
      await notifyAdmins({
        title: "Order accepted",
        message: `Vendor accepted order #${orderId.slice(-6)}.`,
        type: "order_accepted",
        category: "orders",
        metadata: { orderId },
      });
    }

    if (
      nextStatus.toLowerCase().includes("delay") &&
      !prevStatus.toLowerCase().includes("delay")
    ) {
      await notifyAdmins({
        title: "Order delayed",
        message: `Order #${orderId.slice(-6)} is delayed.`,
        type: "order_delayed",
        category: "delivery",
        metadata: { orderId },
      });
    }

    const isCod =
      !after.isPaid &&
      (str(after.paymentMethod).toLowerCase().includes("cod") ||
        str(after.payment_method).toLowerCase().includes("cod"));
    if (
      isCod &&
      nextStatus.toLowerCase().includes("delivered") &&
      !prevStatus.toLowerCase().includes("delivered")
    ) {
      await notifyAdmins({
        title: "COD received",
        message: `Cash on delivery collected for #${orderId.slice(-6)}.`,
        type: "cod_received",
        category: "payments",
        metadata: { orderId },
      });
    }
  }
);

async function tryAutoAssignDriver(
  orderId: string,
  data: Record<string, unknown>
): Promise<void> {
  if (str(data.deliveryBoyId)) return;
  const lat = num(data.lat);
  const lng = num(data.lng);
  const riders = await db
    .collection("delivery_boys")
    .where("isOnline", "==", true)
    .limit(25)
    .get();
  if (riders.empty) return;

  let bestId = "";
  let bestScore = Number.POSITIVE_INFINITY;

  for (const doc of riders.docs) {
    const r = doc.data();
    const rLat = num(r.lat);
    const rLng = num(r.lng);
    const activeOrders = num(r.activeOrders || r.active_orders || 0);
    let dist = 9999;
    if (lat && lng && rLat && rLng) {
      const dLat = lat - rLat;
      const dLng = lng - rLng;
      dist = Math.sqrt(dLat * dLat + dLng * dLng);
    }
    const score = dist * 100 + activeOrders * 50;
    if (score < bestScore) {
      bestScore = score;
      bestId = doc.id;
    }
  }

  if (!bestId) return;
  await db.collection("orders").doc(orderId).update({
    deliveryBoyId: bestId,
    order_status: "rider_assigned",
    autoAssigned: true,
    assignedAt: FieldValue.serverTimestamp(),
  });
}
