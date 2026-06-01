import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import {
  OrderStatus,
  isBeforePickup,
  resolveStatus,
  statusToLegacy,
} from "./order_lifecycle";
import { str } from "./ops_notify";

const db = admin.firestore();

/** Customer cancel — allowed only before pickup (`picked_up`). */
export const cancelOrderByCustomer = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const uid = str(request.auth?.uid);
    const reason = str(request.data?.reason);

    if (!orderId) {
      throw new HttpsError("invalid-argument", "orderId is required.");
    }
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to cancel your order.");
    }

    const ref = db.collection("orders").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const data = snap.data() as Record<string, unknown>;
    const orderUid = str(data.uuid);
    if (orderUid !== uid) {
      throw new HttpsError("permission-denied", "Not your order.");
    }

    if (data.isCancelled === true || data.isDelivered === true) {
      throw new HttpsError("failed-precondition", "Order cannot be cancelled.");
    }

    const status = resolveStatus(data);
    if (!isBeforePickup(status)) {
      throw new HttpsError(
        "failed-precondition",
        "Cancellation is only allowed before pickup."
      );
    }

    await ref.update({
      isCancelled: true,
      status: OrderStatus.CANCELLED_BY_CUSTOMER,
      order_status: statusToLegacy(OrderStatus.CANCELLED_BY_CUSTOMER),
      cancelledBy: "customer",
      cancelReason: reason,
      cancelledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, orderId, status: OrderStatus.CANCELLED_BY_CUSTOMER };
  }
);

/** Vendor cancel — notifies customer, rider, admin via order trigger. */
export const cancelOrderByVendor = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const vendorId = str(request.data?.vendorId);
    const reason = str(request.data?.reason);

    if (!orderId || !vendorId) {
      throw new HttpsError("invalid-argument", "orderId and vendorId are required.");
    }

    const ref = db.collection("orders").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const data = snap.data() as Record<string, unknown>;
    const vIds = [
      str(data.vendorId),
      str(data.vendor_id),
      ...(Array.isArray(data.vendorIds)
        ? (data.vendorIds as unknown[]).map((v) => str(v))
        : []),
    ].filter(Boolean);

    if (!vIds.includes(vendorId)) {
      throw new HttpsError("permission-denied", "Not your order.");
    }

    if (data.isCancelled === true || data.isDelivered === true) {
      throw new HttpsError("failed-precondition", "Order cannot be cancelled.");
    }

    await ref.update({
      isCancelled: true,
      status: OrderStatus.CANCELLED_BY_VENDOR,
      order_status: statusToLegacy(OrderStatus.CANCELLED_BY_VENDOR),
      cancelledBy: "vendor",
      cancelReason: reason,
      cancelledAt: FieldValue.serverTimestamp(),
      vendorRejectedAt: FieldValue.serverTimestamp(),
      vendorRejectedBy: vendorId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { ok: true, orderId, status: OrderStatus.CANCELLED_BY_VENDOR };
  }
);

/** Rider backs out — order returns to assignment queue (not fully cancelled). */
export const cancelOrderByRider = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const riderId = str(request.data?.riderId);
    const reason = str(request.data?.reason);

    if (!orderId || !riderId) {
      throw new HttpsError("invalid-argument", "orderId and riderId are required.");
    }

    const ref = db.collection("orders").doc(orderId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const data = snap.data() as Record<string, unknown>;
    const assigned = str(data.deliveryBoyId ?? data.delivery_boy_id);
    if (assigned !== riderId) {
      throw new HttpsError("permission-denied", "You are not assigned to this order.");
    }

    const status = resolveStatus(data);
    if (
      status === OrderStatus.PICKED_UP ||
      status === OrderStatus.OUT_FOR_DELIVERY ||
      data.isDelivered === true
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot cancel after pickup. Contact support."
      );
    }

    await ref.update({
      deliveryBoyId: "",
      delivery_boy_id: "",
      riderName: "",
      riderPhone: "",
      autoAssigned: false,
      status: OrderStatus.READY_FOR_PICKUP,
      order_status: statusToLegacy(OrderStatus.READY_FOR_PICKUP),
      rider_rejected_by: riderId,
      rider_rejected_at: FieldValue.serverTimestamp(),
      lastRiderCancellation: {
        riderId,
        reason,
        at: FieldValue.serverTimestamp(),
        type: OrderStatus.CANCELLED_BY_RIDER,
      },
      updatedAt: FieldValue.serverTimestamp(),
    });

    await db.collection("delivery_boys").doc(riderId).set(
      {
        activeOrders: FieldValue.increment(-1),
        active_orders: FieldValue.increment(-1),
        rejected_orders: FieldValue.increment(1),
      },
      { merge: true }
    );

    await db
      .collection("rider_orders")
      .doc(riderId)
      .collection("orders")
      .doc(orderId)
      .delete()
      .catch(() => undefined);

    return { ok: true, orderId, status: OrderStatus.READY_FOR_PICKUP };
  }
);
