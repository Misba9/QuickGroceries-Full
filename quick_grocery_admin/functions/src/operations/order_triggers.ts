import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import {
  appendDeliveryTracking,
  getOpsSettings,
  notifyAdmins,
  notifyCustomer,
  notifyDeliveryRider,
  notifyVendor,
  num,
  str,
  writeGlobalNotification,
  writeUserInbox,
} from "./ops_notify";
import {
  OrderStatus,
  resolveStatus,
  statusToLegacy,
  vendorMirrorPatch,
} from "./order_lifecycle";
import { autoAssignNearestRider, haversineKm } from "./rider_assignment";
import { processReferralOnOrderDelivered } from "../refer_earn/refer_earn_engine";
import {
  currentTipAmount,
  markTipEarnedOnDelivered,
} from "../delivery_tips/delivery_tips_engine";
import { orderTipAmount } from "./delivery_earnings";
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
  return sum + num(data.delivery_charge ?? data.deliveryCharge);
}

function paymentLabel(data: Record<string, unknown>): string {
  const m = str(data.paymentMethod);
  if (m) return m.toUpperCase();
  return data.isPaid ? "PAID" : "COD";
}

function vendorIds(data: Record<string, unknown>): string[] {
  const ids = new Set<string>();
  const products = (data.products as unknown[]) || [];
  for (const p of products) {
    const row = p as Record<string, unknown>;
    const id = str(row.vendor_id || row.vendorId);
    if (id) ids.add(id);
  }
  const top = str(data.vendorId || data.vendor_id);
  if (top) ids.add(top);
  const list = data.vendorIds;
  if (Array.isArray(list)) {
    for (const v of list) {
      const id = str(v);
      if (id) ids.add(id);
    }
  }
  return [...ids];
}

async function resolveCustomerPhone(uid: string): Promise<string> {
  if (!uid) return "";
  const cust = await db.collection("customers").doc(uid).get();
  if (cust.exists) {
    const phone = str(
      cust.data()?.phone || cust.data()?.phoneNumber || cust.data()?.mobile,
    );
    if (phone) return phone;
  }
  const user = await db.collection("users").doc(uid).get();
  if (user.exists) {
    return str(
      user.data()?.phone || user.data()?.phoneNumber || user.data()?.mobile,
    );
  }
  return "";
}

/** Backfill contact phone on orders when address snapshot omitted mobile. */
async function ensureOrderCustomerPhone(
  orderId: string,
  data: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const existing = str(
    data.phone || data.customerPhone || data.phoneNumber || data.mobile,
  );
  if (existing) return data;

  const uid = str(data.uuid);
  const phone = await resolveCustomerPhone(uid);
  if (!phone) return data;

  const addressSnapshot =
    data.address_snapshot && typeof data.address_snapshot === "object"
      ? { ...(data.address_snapshot as Record<string, unknown>), mobile: phone }
      : { mobile: phone };

  await db.collection("orders").doc(orderId).set(
    {
      phone,
      customerPhone: phone,
      phoneNumber: phone,
      address_snapshot: addressSnapshot,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return {
    ...data,
    phone,
    customerPhone: phone,
    phoneNumber: phone,
    address_snapshot: addressSnapshot,
  };
}

async function vendorNames(ids: string[]): Promise<string> {
  const names: string[] = [];
  for (const id of ids.slice(0, 5)) {
    const v = await db.collection("vendors").doc(id).get();
    if (v.exists) names.push(str(v.data()?.name || v.data()?.shopName || id));
  }
  return names.join(", ") || "—";
}

async function primaryVendorSnapshot(
  data: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const ids = vendorIds(data);
  const vendorId = ids[0] ?? "";
  if (!vendorId) return {};

  const v = await db.collection("vendors").doc(vendorId).get();
  if (!v.exists) return { vendorId };

  const d = v.data() as Record<string, unknown>;
  const pickupLat = num(d.lat ?? d.latitude ?? d.shop_lat);
  const pickupLng = num(d.lng ?? d.longitude ?? d.shop_lng);
  const deliveryLat = num(data.lat);
  const deliveryLng = num(data.lng);

  let routeDistanceKm = num(data.routeDistanceKm ?? data.route_distance_km);
  let expectedDeliveryMinutes = num(
    data.expectedDeliveryMinutes ?? data.expected_delivery_minutes,
  );

  if (!routeDistanceKm && pickupLat && pickupLng && deliveryLat && deliveryLng) {
    routeDistanceKm = haversineKm(pickupLat, pickupLng, deliveryLat, deliveryLng);
  }
  if (!expectedDeliveryMinutes && routeDistanceKm) {
    expectedDeliveryMinutes = Math.max(8, Math.round((routeDistanceKm / 25) * 60 + 5));
  }

  return {
    vendorId,
    vendorName: str(d.shopName || d.shop_name || d.name),
    vendorPhone: str(d.phone),
    pickupAddress: str(d.shopAddress || d.shop_address),
    pickupLat: pickupLat || null,
    pickupLng: pickupLng || null,
    routeDistanceKm: routeDistanceKm || null,
    expectedDeliveryMinutes: expectedDeliveryMinutes || null,
  };
}

async function ensureRiderAcceptedSnapshot(
  orderId: string,
  after: Record<string, unknown>,
): Promise<void> {
  if (str(after.vendorName) && str(after.pickupAddress)) return;

  const patch = await primaryVendorSnapshot(after);
  if (Object.keys(patch).length === 0) return;

  await db.collection("orders").doc(orderId).set(
    { ...patch, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
}

async function syncVendorOrderMirrors(
  orderId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const patch = vendorMirrorPatch(data);
  const ids = vendorIds(data);
  if (ids.length === 0) return;
  const batch = db.batch();
  for (const vendorId of ids) {
    batch.set(
      db.collection("vendor_orders").doc(vendorId).collection("orders").doc(orderId),
      { orderId, vendorId, ...patch },
      { merge: true },
    );
  }
  await batch.commit();
}

/** Stage 1 — customer order placed: notify admin, vendor, customer. No auto-assign yet. */
export const onOrderCreated = onDocumentCreated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const orderId = event.params.orderId;
    console.log(`[ORDER:CREATED] orderId=${orderId} FUNCTION START`);
    let data = snap.data() as Record<string, unknown>;
    data = await ensureOrderCustomerPhone(orderId, data);
    const customer = str(data.customer_name || data.customerName);
    const total = orderTotal(data);
    const payment = paymentLabel(data);
    const vIds = vendorIds(data);
    const vName = await vendorNames(vIds);

    console.log(
      `[ORDER:CREATED] orderId=${orderId} vendors=${vIds.join(",")} ` +
        `customer=${customer} total=${total}`,
    );

    await notifyAdmins({
      title: "New Order Received",
      message: `Order #${orderId.slice(-6)} · ${customer} · ₹${total.toFixed(0)} · ${vName}`,
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
        title: "🛒 New Order",
        message: `New order from ${customer} — accept within 2 min`,
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

    await appendDeliveryTracking(orderId, "order_placed", {
      status: OrderStatus.ORDER_PLACED,
      customer,
      total,
    });

    const settings = await getOpsSettings();
    if (settings.autoAssignDriver && !str(data.deliveryBoyId)) {
      await autoAssignNearestRider(orderId).catch((e) =>
        console.warn("[onOrderCreated] auto-assign failed", orderId, e),
      );
    }
    console.log(`[ORDER:CREATED] orderId=${orderId} FUNCTION END`);
  },
);

/** Status / rider / cancel changes → sync mirrors, notify parties, auto-dispatch when ready. */
export const onOrderUpdated = onDocumentUpdated(
  { document: "orders/{orderId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before.data() as Record<string, unknown> | undefined;
    let after = event.data?.after.data() as Record<string, unknown> | undefined;
    if (!before || !after) return;
    const orderId = event.params.orderId;
    console.log(`[ORDER:UPDATED] orderId=${orderId} FUNCTION START`);
    after = await ensureOrderCustomerPhone(orderId, after);

    const prevStatus = resolveStatus(before);
    const nextStatus = resolveStatus(after);
    const prevCancelled = Boolean(before.isCancelled);
    const nextCancelled = Boolean(after.isCancelled);
    const prevRider = str(before.deliveryBoyId);
    const nextRider = str(after.deliveryBoyId);
    const uid = str(after.uuid);

    // Keep vendor mirror in sync on every update.
    await syncVendorOrderMirrors(orderId, after);

    if (nextStatus !== prevStatus) {
      await appendDeliveryTracking(orderId, "status_change", {
        from: prevStatus,
        to: nextStatus,
      });
      if (nextStatus === OrderStatus.DELIVERY_ASSIGNED) {
        await ensureRiderAcceptedSnapshot(orderId, after);
      }
      await handleStatusTransition(orderId, prevStatus, nextStatus, after, uid);
    }

    if (nextCancelled && !prevCancelled) {
      await handleCancellation(orderId, after, uid);
    }

    if (nextRider && nextRider !== prevRider) {
      await handleRiderAssigned(orderId, nextRider, after);
    }

    if (!nextRider && prevRider && nextRider !== prevRider) {
      await db
        .collection("rider_orders")
        .doc(prevRider)
        .collection("orders")
        .doc(orderId)
        .delete()
        .catch(() => undefined);

      if (resolveStatus(after) === OrderStatus.ORDER_PLACED) {
        await notifyAdmins({
          title: "Rider cancelled assignment",
          message: `Order #${orderId.slice(-6)} returned to awaiting assignment.`,
          type: "driver_rejected",
          category: "delivery",
          soundAlert: true,
          metadata: {
            orderId,
            deliveryBoyId: prevRider,
            cancellationType: OrderStatus.CANCELLED_BY_RIDER,
          },
        });
        await appendDeliveryTracking(orderId, "cancelled_by_rider", {
          riderId: prevRider,
          returnedTo: OrderStatus.ORDER_PLACED,
        });
      }
    }

    const prevPaid = Boolean(before.isPaid);
    const nextPaid = Boolean(after.isPaid);
    const prevTip = currentTipAmount(before);
    const nextTip = currentTipAmount(after);
    if (nextTip > prevTip && nextTip > 0) {
      const riderId = str(after.deliveryBoyId ?? after.delivery_boy_id);
      if (riderId) {
        const delta = nextTip - prevTip;
        await notifyDeliveryRider(riderId, {
          title: "Tip received",
          message: `🎉 You received a ₹${delta} tip from a customer.`,
          type: "delivery_tip",
          metadata: { orderId, tipAmount: nextTip, delta },
        });
      }
    }

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
    console.log(
      `[ORDER:UPDATED] orderId=${orderId} FUNCTION END ` +
        `status ${prevStatus}→${nextStatus}`,
    );
  },
);

async function handleStatusTransition(
  orderId: string,
  prevStatus: string,
  nextStatus: string,
  after: Record<string, unknown>,
  uid: string,
): Promise<void> {
  const customer = str(after.customer_name || after.customerName);
  const normalized = resolveStatus({ ...after, status: nextStatus });

  switch (normalized) {
    case OrderStatus.ORDER_PLACED:
      if (uid && prevStatus !== nextStatus) {
        await writeUserInbox(uid, {
          title: "Order placed",
          body: `We received your order #${orderId.slice(-6)}.`,
          type: "order",
          targetId: orderId,
          deepLink: `/orders/${orderId}`,
        });
      }
      break;

    case OrderStatus.DELIVERY_ASSIGNED:
      if (uid) {
        await notifyCustomer(uid, {
          title: "Delivery partner assigned",
          body: `A delivery partner is assigned to order #${orderId.slice(-6)}.`,
          type: "delivery_assigned",
          orderId,
          deepLink: `/orders/${orderId}`,
        });
      }
      for (const vendorId of vendorIds(after)) {
        await notifyVendor(vendorId, {
          title: "Order assigned",
          message: `Order #${orderId.slice(-6)} assigned to a delivery partner.`,
          type: "driver_assigned",
          metadata: { orderId },
        });
      }
      break;

    case OrderStatus.CANCELLED_BY_VENDOR:
      if (uid) {
        await notifyCustomer(uid, {
          title: "Order cancelled",
          body: `The store cancelled order #${orderId.slice(-6)}.`,
          type: "order_cancelled",
          orderId,
        });
      }
      break;

    case OrderStatus.OUT_FOR_DELIVERY:
      if (uid) {
        await notifyCustomer(uid, {
          title: "Out for delivery",
          body: `Your order #${orderId.slice(-6)} is on the way.`,
          type: "order_out_for_delivery",
          orderId,
        });
        await writeUserInbox(uid, {
          title: "Out for delivery",
          body: `Your order #${orderId.slice(-6)} is on the way to you.`,
          type: "delivery",
          targetId: orderId,
          deepLink: `/orders/${orderId}`,
        });
      }
      break;

    case OrderStatus.DELIVERED: {
      const riderId = str(after.deliveryBoyId ?? after.delivery_boy_id);
      await appendDeliveryTracking(orderId, "delivered", {
        deliveryDurationSec: num(
          after.deliveryDurationSec ?? after.delivery_duration_seconds
        ),
        distanceTravelledKm: num(
          after.distanceTravelledKm ?? after.distance_travelled_km
        ),
      });
      await notifyAdmins({
        title: "Order completed",
        message: `Order #${orderId.slice(-6)} has been delivered.`,
        type: "order_delivered",
        category: "delivery",
        metadata: { orderId },
      });
      for (const vendorId of vendorIds(after)) {
        await notifyVendor(vendorId, {
          title: "Order delivered",
          message: `Order #${orderId.slice(-6)} was delivered.`,
          type: "order_delivered",
          metadata: { orderId },
        });
      }
      if (uid) {
        const tip = orderTipAmount(after);
        await notifyCustomer(uid, {
          title: "Delivered",
          body:
            tip > 0
              ? "Your order has been delivered successfully."
              : "Your order has been delivered. Would you like to thank your delivery partner with a tip?",
          type: "order_delivered",
          orderId,
        });
        await writeUserInbox(uid, {
          title: "Delivered",
          body:
            tip > 0
              ? "Your order has been delivered successfully."
              : "Would you like to thank your delivery partner with a tip?",
          type: "delivery",
          targetId: orderId,
          deepLink: `/orders/${orderId}`,
        });
      }
      if (riderId) {
        await notifyDeliveryRider(riderId, {
          title: "Delivery completed",
          message: `Order #${orderId.slice(-6)} delivery completed.`,
          type: "delivery_completed",
          metadata: { orderId },
        });
      }
      try {
        await markTipEarnedOnDelivered(orderId, after);
      } catch (e) {
        console.warn("[onOrderUpdated] markTipEarned failed", orderId, e);
      }
      try {
        await processReferralOnOrderDelivered(orderId, after);
      } catch (e) {
        console.error("processReferralOnOrderDelivered failed", orderId, e);
      }
      break;
    }

    default:
      break;
  }
}

async function handleCancellation(
  orderId: string,
  after: Record<string, unknown>,
  uid: string,
): Promise<void> {
  const status = resolveStatus(after);
  const cancelledBy = str(after.cancelledBy).toLowerCase();
  const shortId = orderId.slice(-6);

  let adminTitle = "Order cancelled";
  let adminMsg = `Order #${shortId} was cancelled.`;
  let customerTitle = "Order cancelled";
  let customerBody = `Your order #${shortId} was cancelled.`;
  let vendorTitle = "Order cancelled";
  let vendorMsg = `Order #${shortId} was cancelled.`;
  let riderTitle = "Order cancelled";
  let riderMsg = `Order #${shortId} has been cancelled.`;

  if (
    status === OrderStatus.CANCELLED_BY_CUSTOMER ||
    cancelledBy === "customer"
  ) {
    adminTitle = "Customer cancelled order";
    adminMsg = `Customer cancelled order #${shortId}.`;
    vendorTitle = "Order cancelled by customer";
    vendorMsg = `Order #${shortId} was cancelled by the customer.`;
    riderTitle = "Delivery cancelled";
    riderMsg = `Order #${shortId} was cancelled by the customer.`;
  } else if (
    status === OrderStatus.CANCELLED_BY_VENDOR ||
    cancelledBy === "vendor"
  ) {
    adminTitle = "Vendor cancelled order";
    adminMsg = `Vendor cancelled order #${shortId}.`;
    customerTitle = "Order cancelled by store";
    customerBody = `Your order #${shortId} was cancelled by the store.`;
    riderTitle = "Delivery cancelled";
    riderMsg = `Order #${shortId} was cancelled by the vendor.`;
  }

  await notifyAdmins({
    title: `❌ ${adminTitle}`,
    message: adminMsg,
    type: "order_cancelled",
    category: "orders",
    soundAlert: true,
    metadata: { orderId, cancelledBy, status },
  });

  const customer = str(after.customer_name || after.customerName);
  const phone = str(after.phone);
  const vIds = vendorIds(after);

  await writeGlobalNotification({
    type: "order_cancelled",
    orderId,
    customerName: customer,
    customerPhone: phone,
    vendorId: vIds[0] || "",
    deliveryBoyId: str(after.deliveryBoyId),
    cancelledBy: cancelledBy || "user",
    title: `❌ Order Cancelled`,
    body: `Order #${shortId} cancelled by ${cancelledBy || "customer"}.`,
    sender: cancelledBy || "customer",
    receiver: "admin",
    metadata: { status, vendorIds: vIds },
  });

  for (const vendorId of vIds) {
    await notifyVendor(vendorId, {
      title: "❌ Order Cancelled",
      message: vendorMsg,
      type: "order_cancelled",
      metadata: { orderId, cancelledBy, customerName: customer },
    });
  }
  const riderId = str(after.deliveryBoyId);
  if (riderId) {
    await notifyDeliveryRider(riderId, {
      title: "❌ Delivery Cancelled",
      message: riderMsg,
      type: "order_cancelled",
      metadata: { orderId, cancelledBy },
    });
  }
  if (uid) {
    await writeUserInbox(uid, {
      title: customerTitle,
      body: customerBody,
      type: "order_cancelled",
      targetId: orderId,
      deepLink: `/orders/${orderId}`,
    });
    await notifyCustomer(uid, {
      title: customerTitle,
      body: customerBody,
      type: "order_cancelled",
      orderId,
      deepLink: `/orders/${orderId}`,
    });
  }
  await appendDeliveryTracking(orderId, "cancelled", {
    reason: str(after.cancelReason),
    cancelledBy,
    status,
  });
}

async function handleRiderAssigned(
  orderId: string,
  riderId: string,
  after: Record<string, unknown>,
): Promise<void> {
  await notifyDeliveryRider(riderId, {
    title: "🛵 New Delivery Assigned",
    message: `Accept order #${orderId.slice(-6)} to start pickup.`,
    type: "delivery_assigned",
    metadata: { orderId },
  });
  await appendDeliveryTracking(orderId, "rider_assigned", { deliveryBoyId: riderId });
  await db
    .collection("rider_orders")
    .doc(riderId)
    .collection("orders")
    .doc(orderId)
    .set(
      {
        orderId,
        customer_name: str(after.customer_name || after.customerName),
        phone: str(after.phone),
        address: str(after.address),
        lat: num(after.lat),
        lng: num(after.lng),
        deliverySlot: after.deliverySlot ?? after.delivery_slot ?? null,
        deliveryInstructions:
          after.deliveryInstructions ?? after.delivery_instructions ?? null,
        status: resolveStatus(after),
        assignedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  await notifyAdmins({
    title: "Rider assigned",
    message: `Rider assigned to order #${orderId.slice(-6)}.`,
    type: "driver_assigned",
    category: "delivery",
    metadata: { orderId, deliveryBoyId: riderId },
  });
}
