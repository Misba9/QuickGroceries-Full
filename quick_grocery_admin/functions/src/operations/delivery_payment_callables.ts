import { HttpsError, onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
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

function orderGrandTotal(data: Record<string, unknown>): number {
  const bill = data.bill as Record<string, unknown> | undefined;
  if (bill) {
    const t = num(bill.grandTotal ?? bill.total);
    if (t > 0) return t;
  }
  const products = (data.products as unknown[]) || [];
  let sum = 0;
  for (const raw of products) {
    const p = raw as Record<string, unknown>;
    sum += num(p.totalPrice) || num(p.price) * num(p.itemCount ?? p.quantity ?? 1);
  }
  return sum + num(data.deliveryCharge ?? data.delivery_charge);
}

function isCodOrder(data: Record<string, unknown>): boolean {
  const method = str(data.paymentMethod ?? data.payment_method).toLowerCase();
  return method === "cod" || method === "cash_on_delivery";
}

function isAlreadyPaid(data: Record<string, unknown>): boolean {
  if (data.isPaid === true) return true;
  return str(data.paymentStatus ?? data.payment_status).toLowerCase() === "paid";
}

/**
 * Rider records COD collection (cash or UPI) before delivery can complete.
 */
export const recordDeliveryPaymentCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const orderId = str(request.data?.orderId);
    const riderId = str(request.data?.riderId);
    const collectionMethod = str(request.data?.collectionMethod).toLowerCase();

    if (!orderId || !riderId) {
      throw new HttpsError("invalid-argument", "orderId and riderId are required.");
    }
    if (collectionMethod !== "cash" && collectionMethod !== "upi") {
      throw new HttpsError(
        "invalid-argument",
        "collectionMethod must be cash or upi.",
      );
    }

    const orderRef = db.collection("orders").doc(orderId);
    const snap = await orderRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const order = snap.data() as Record<string, unknown>;
    const assigned = str(order.deliveryBoyId ?? order.delivery_boy_id);
    if (!assigned || assigned !== riderId) {
      throw new HttpsError("permission-denied", "You are not assigned to this order.");
    }

    if (!isCodOrder(order)) {
      throw new HttpsError(
        "failed-precondition",
        "This order was paid online — no collection needed.",
      );
    }

    if (isAlreadyPaid(order)) {
      return { ok: true, orderId, alreadyPaid: true };
    }

    const amount = orderGrandTotal(order);
    if (amount <= 0) {
      throw new HttpsError("failed-precondition", "Invalid order amount.");
    }

    await orderRef.set(
      {
        paymentStatus: "paid",
        payment_status: "paid",
        isPaid: true,
        collectionMethod,
        collection_method: collectionMethod,
        paidAmount: amount,
        paid_amount: amount,
        paidAt: FieldValue.serverTimestamp(),
        paid_at: FieldValue.serverTimestamp(),
        collectedBy: riderId,
        collected_by: riderId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return { ok: true, orderId, paidAmount: amount, collectionMethod };
  },
);
