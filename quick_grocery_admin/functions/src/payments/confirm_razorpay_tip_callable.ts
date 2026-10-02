import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import {
  currentTipAmount,
  updateOrderTipAmount,
  validateTipAmount,
} from "../delivery_tips/delivery_tips_engine";
import { getDeliveryTipSettings } from "../delivery_tips/delivery_tips_settings";
import { verifyRazorpayCheckoutSignature } from "./razorpay_api";
import { razorpaySecretBindings } from "./razorpay_config";
import { consumeRazorpayCheckoutOrder } from "./razorpay_orders_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/**
 * Verifies Razorpay tip payment, then applies the tip increase server-side.
 */
export const confirmRazorpayTipPaymentCallable = onCall(
  {
    ...callableBaseOptions(),
    secrets: razorpaySecretBindings(),
    invoker: "public",
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to confirm tip payment.");
    }

    const groceryOrderId = str(req.data?.orderId);
    const tipDelta = Math.round(num(req.data?.tipAmount));
    const paymentId = str(req.data?.razorpay_payment_id);
    const razorpayOrderId = str(req.data?.razorpay_order_id);
    const signature = str(req.data?.razorpay_signature);

    if (!groceryOrderId || tipDelta <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "orderId and positive tipAmount are required.",
      );
    }
    if (!paymentId || !razorpayOrderId || !signature) {
      throw new HttpsError(
        "failed-precondition",
        "Tip payment verification requires payment_id, order_id, and signature.",
      );
    }

    verifyRazorpayCheckoutSignature({
      orderId: razorpayOrderId,
      paymentId,
      signature,
    });

    const settings = await getDeliveryTipSettings();
    validateTipAmount(tipDelta, settings);

    const consumed = await consumeRazorpayCheckoutOrder({
      uid,
      razorpayOrderId,
      paymentId,
      expectedAmountPaise: tipDelta * 100,
      purpose: "delivery_tip",
    });

    if (consumed.alreadyConsumed) {
      return {
        ok: true,
        duplicate: true,
        paymentId,
        orderId: groceryOrderId,
      };
    }

    const snap = await admin
      .firestore()
      .collection("orders")
      .doc(groceryOrderId)
      .get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const current = currentTipAmount(
      snap.data() as Record<string, unknown>,
    );
    const newTotal = current + tipDelta;

    await updateOrderTipAmount(groceryOrderId, uid, newTotal, {
      allowAfterDelivered: true,
    });

    await admin.firestore().collection("tip_transactions").add({
      orderId: groceryOrderId,
      customerId: uid,
      amount: tipDelta,
      paymentStatus: "paid",
      paymentRef: paymentId,
      razorpayOrderId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      paymentId,
      tipAmount: newTotal,
      orderId: groceryOrderId,
    };
  },
);
