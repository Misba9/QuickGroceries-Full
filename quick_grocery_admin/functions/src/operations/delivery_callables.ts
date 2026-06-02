import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import { orderEarning } from "./delivery_earnings";
import { OrderStatus, resolveStatus, statusToLegacy } from "./order_lifecycle";
import { notifyAdmins, str } from "./ops_notify";

const db = admin.firestore();

function num(v: unknown): number {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim()) {
    const n = Number(v);
    if (Number.isFinite(n)) return n;
  }
  return 0;
}

/**
 * Rider confirms delivery (no OTP). Status → delivered + wallet credit.
 * Firestore `onOrderUpdated` notifies customer, vendor, and admin.
 */
export const confirmDelivery = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const riderId = str(request.data?.riderId);
    const deliveryDurationSec = Math.max(
      0,
      Math.round(num(request.data?.deliveryDurationSec))
    );
    const distanceTravelledKm = Math.max(
      0,
      num(request.data?.distanceTravelledKm)
    );

    if (!orderId || !riderId) {
      throw new HttpsError(
        "invalid-argument",
        "orderId and riderId are required."
      );
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderSnap.data() as Record<string, unknown>;
    const status = resolveStatus(order);
    if (status !== OrderStatus.OUT_FOR_DELIVERY) {
      throw new HttpsError(
        "failed-precondition",
        "Order is not out for delivery."
      );
    }

    const assignedRider = str(order.deliveryBoyId ?? order.delivery_boy_id);
    if (!assignedRider || assignedRider !== riderId) {
      throw new HttpsError(
        "permission-denied",
        "You are not assigned to this order."
      );
    }

    const deliveredAt = new Date();
    const earning = orderEarning(order);

    await orderRef.set(
      {
        isDelivered: true,
        order_status: statusToLegacy(OrderStatus.DELIVERED),
        status: OrderStatus.DELIVERED,
        deliveredTime: deliveredAt.toISOString(),
        deliveredAt: FieldValue.serverTimestamp(),
        deliveredBy: riderId,
        delivered_by: riderId,
        deliveryDurationSec,
        delivery_duration_seconds: deliveryDurationSec,
        distanceTravelledKm,
        distance_travelled_km: distanceTravelledKm,
        riderId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const riderRef = db.collection("delivery_boys").doc(riderId);
    await riderRef.set(
      {
        activeOrders: FieldValue.increment(-1),
        active_orders: FieldValue.increment(-1),
        completed_orders: FieldValue.increment(1),
        total_deliveries: FieldValue.increment(1),
        activeOrderId: "",
        ...(earning > 0
          ? {
              wallet_balance: FieldValue.increment(earning),
              total_earnings: FieldValue.increment(earning),
            }
          : {}),
      },
      { merge: true }
    );

    if (earning > 0) {
      await riderRef.collection("wallet_transactions").add({
        type: "delivery_earning",
        amount: earning,
        order_id: orderId,
        note: "Delivery completed",
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    return {
      ok: true,
      orderId,
      earning,
      deliveryDurationSec,
      distanceTravelledKm,
    };
  }
);

/** Rider could not reach customer — log event and alert admin. */
export const reportCustomerNotReachable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const riderId = str(request.data?.riderId);
    const note = str(request.data?.note);

    if (!orderId || !riderId) {
      throw new HttpsError(
        "invalid-argument",
        "orderId and riderId are required."
      );
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = orderSnap.data() as Record<string, unknown>;
    const assignedRider = str(order.deliveryBoyId ?? order.delivery_boy_id);
    if (!assignedRider || assignedRider !== riderId) {
      throw new HttpsError(
        "permission-denied",
        "You are not assigned to this order."
      );
    }

    await orderRef.set(
      {
        customerNotReachable: true,
        customer_not_reachable: true,
        customerNotReachableAt: FieldValue.serverTimestamp(),
        customer_not_reachable_at: FieldValue.serverTimestamp(),
        customerNotReachableBy: riderId,
        customer_not_reachable_by: riderId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await orderRef.collection("delivery_events").add({
      type: "customer_not_reachable",
      riderId,
      note: note || null,
      createdAt: FieldValue.serverTimestamp(),
    });

    await notifyAdmins({
      title: "Customer not reachable",
      message: `Rider could not reach customer for order #${orderId.slice(-6)}.`,
      type: "delivery_delayed",
      category: "delivery",
      metadata: { orderId, riderId },
    });

    return { ok: true, orderId };
  }
);
