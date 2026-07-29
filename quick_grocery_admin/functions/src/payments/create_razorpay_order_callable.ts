import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { createRazorpayOrderApi } from "./razorpay_api";
import { readRazorpayKeys, razorpaySecretBindings } from "./razorpay_config";
import {
  saveRazorpayCheckoutOrder,
  type RazorpayCheckoutPurpose,
} from "./razorpay_orders_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/**
 * Creates a Razorpay Order for checkout / tip payments.
 * Returns public key id + order_id for the Flutter SDK (never the secret).
 */
export const createRazorpayOrderCallable = onCall(
  {
    ...callableBaseOptions(),
    secrets: razorpaySecretBindings(),
    invoker: "public",
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to start payment.");
    }

    const amountRupees = num(req.data?.amount);
    const amountPaiseRaw = num(req.data?.amountPaise);
    const amountPaise =
      amountPaiseRaw > 0
        ? Math.round(amountPaiseRaw)
        : Math.round(amountRupees * 100);

    if (amountPaise < 100) {
      throw new HttpsError(
        "invalid-argument",
        "Amount must be at least ₹1.00.",
      );
    }

    const purposeRaw = str(req.data?.purpose) || "grocery_order";
    const purpose = (
      purposeRaw === "delivery_tip" ? "delivery_tip" : "grocery_order"
    ) as RazorpayCheckoutPurpose;

    const groceryIdempotencyKey = str(req.data?.idempotencyKey);
    const tipOrderId = str(req.data?.orderId);
    if (purpose === "delivery_tip" && !tipOrderId) {
      throw new HttpsError(
        "invalid-argument",
        "orderId is required for tip payments.",
      );
    }

    const receipt = `qg_${uid.slice(0, 6)}_${Date.now().toString(36)}`.slice(
      0,
      40,
    );

    const order = await createRazorpayOrderApi({
      amountPaise,
      currency: "INR",
      receipt,
      notes: {
        uid,
        purpose,
        ...(groceryIdempotencyKey
          ? { groceryIdempotencyKey }
          : {}),
        ...(tipOrderId ? { tipOrderId } : {}),
      },
    });

    await saveRazorpayCheckoutOrder({
      uid,
      razorpayOrderId: order.id,
      amountPaise: order.amount,
      currency: order.currency,
      purpose,
      ...(groceryIdempotencyKey
        ? { groceryIdempotencyKey }
        : {}),
      ...(tipOrderId ? { tipOrderId } : {}),
    });

    const { keyId } = readRazorpayKeys();
    return {
      keyId,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      purpose,
    };
  },
);
