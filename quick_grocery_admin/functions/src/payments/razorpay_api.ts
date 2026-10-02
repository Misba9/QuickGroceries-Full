import * as crypto from "crypto";
import { HttpsError } from "firebase-functions/v2/https";
import { readRazorpayKeys } from "./razorpay_config";

export interface RazorpayOrderCreated {
  id: string;
  amount: number;
  currency: string;
  receipt: string;
  status: string;
}

/** Creates a Razorpay Order via Orders API (server-side only). */
export async function createRazorpayOrderApi(params: {
  amountPaise: number;
  currency?: string;
  receipt: string;
  notes?: Record<string, string>;
}): Promise<RazorpayOrderCreated> {
  const { keyId, keySecret } = readRazorpayKeys();
  const amountPaise = Math.round(params.amountPaise);
  if (!Number.isFinite(amountPaise) || amountPaise < 100) {
    throw new HttpsError(
      "invalid-argument",
      "Payment amount must be at least ₹1.00.",
    );
  }

  const body = {
    amount: amountPaise,
    currency: params.currency || "INR",
    receipt: params.receipt.slice(0, 40),
    payment_capture: 1,
    notes: params.notes ?? {},
  };

  const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");
  const res = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    const description =
      (json.error as { description?: string } | undefined)?.description ||
      `Razorpay order create failed (${res.status})`;
    console.error("createRazorpayOrderApi", res.status, json);
    throw new HttpsError("internal", description);
  }

  const id = String(json.id || "");
  if (!id) {
    throw new HttpsError("internal", "Razorpay returned an empty order id.");
  }

  return {
    id,
    amount: Number(json.amount) || amountPaise,
    currency: String(json.currency || "INR"),
    receipt: String(json.receipt || params.receipt),
    status: String(json.status || "created"),
  };
}

/**
 * Official Razorpay checkout signature:
 * HMAC_SHA256(order_id + "|" + payment_id, key_secret)
 */
export function verifyRazorpayCheckoutSignature(params: {
  orderId: string;
  paymentId: string;
  signature: string;
}): void {
  const orderId = params.orderId.trim();
  const paymentId = params.paymentId.trim();
  const signature = params.signature.trim();
  if (!orderId || !paymentId || !signature) {
    throw new HttpsError(
      "failed-precondition",
      "Payment verification requires order_id, payment_id, and signature.",
    );
  }

  const { keySecret } = readRazorpayKeys();
  const expected = crypto
    .createHmac("sha256", keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(signature, "utf8");
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    throw new HttpsError(
      "permission-denied",
      "Payment signature verification failed.",
    );
  }
}

/**
 * Verifies a payment by fetching it from Razorpay (used when Orders API /
 * checkout signature triad is unavailable).
 */
export async function assertRazorpayPaymentCaptured(params: {
  paymentId: string;
  expectedAmountPaise: number;
}): Promise<void> {
  const paymentId = params.paymentId.trim();
  if (!paymentId) {
    throw new HttpsError("failed-precondition", "Missing razorpay payment id.");
  }

  const { keyId, keySecret } = readRazorpayKeys();
  const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");
  const res = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
    method: "GET",
    headers: { Authorization: `Basic ${auth}` },
  });
  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    const description =
      (json.error as { description?: string } | undefined)?.description ||
      `Razorpay payment lookup failed (${res.status})`;
    throw new HttpsError("permission-denied", description);
  }

  const status = String(json.status || "");
  const amount = Number(json.amount) || 0;
  if (status !== "captured" && status !== "authorized") {
    throw new HttpsError(
      "failed-precondition",
      `Payment is not successful (status=${status || "unknown"}).`,
    );
  }
  if (Math.abs(amount - params.expectedAmountPaise) > 0) {
    throw new HttpsError(
      "permission-denied",
      "Paid amount does not match the order total.",
    );
  }
}
