import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import {
  clearDeliveryOtp,
  orderEarning,
  verifyDeliveryOtp,
} from "./delivery_otp";
import { OrderStatus, resolveStatus, statusToLegacy } from "./order_lifecycle";
import { str } from "./ops_notify";

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
 * Stage 9 — rider confirms delivery with customer OTP.
 * Only succeeds when code matches; then status → delivered + metrics saved.
 */
export const confirmDeliveryWithOtp = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const riderId = str(request.data?.riderId);
    const otp = str(request.data?.otp);
    const deliveryDurationSec = Math.max(
      0,
      Math.round(num(request.data?.deliveryDurationSec))
    );
    const distanceTravelledKm = Math.max(
      0,
      num(request.data?.distanceTravelledKm)
    );

    if (!orderId || !riderId || otp.length !== 4) {
      throw new HttpsError(
        "invalid-argument",
        "orderId, riderId, and 4-digit OTP are required."
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

    const check = verifyDeliveryOtp(order, otp, orderId);
    if (!check.ok) {
      const attempts =
        Number(order.deliveryOtpAttempts ?? order.delivery_otp_attempts ?? 0) +
        1;
      await orderRef.update({
        deliveryOtpAttempts: attempts,
        delivery_otp_attempts: attempts,
      });
      throw new HttpsError("invalid-argument", check.reason);
    }

    const customerUid = str(order.uuid);
    const deliveredAt = new Date();
    const earning = orderEarning(order);

    await orderRef.set(
      {
        isDelivered: true,
        order_status: statusToLegacy(OrderStatus.DELIVERED),
        status: OrderStatus.DELIVERED,
        deliveredTime: deliveredAt.toISOString(),
        deliveredAt: FieldValue.serverTimestamp(),
        deliveryDurationSec,
        delivery_duration_seconds: deliveryDurationSec,
        distanceTravelledKm,
        distance_travelled_km: distanceTravelledKm,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await clearDeliveryOtp(orderId, customerUid);

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
