import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { OrderStatus, resolveStatus } from "../operations/order_lifecycle";
import { getDeliveryTipSettings } from "./delivery_tips_settings";
import { DeliveryTipSettings } from "./delivery_tips_types";

const db = admin.firestore();

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

export function currentTipAmount(data: Record<string, unknown>): number {
  const direct = num(data.tipAmount);
  if (direct > 0) return direct;
  const bill = data.bill as Record<string, unknown> | undefined;
  return num(bill?.deliveryPartnerTip ?? bill?.tipAmount);
}

export function validateTipAmount(
  amount: number,
  settings: DeliveryTipSettings,
): void {
  if (amount <= 0) return;
  if (!settings.enabled) {
    throw new HttpsError(
      "failed-precondition",
      "Delivery partner tips are currently disabled.",
    );
  }
  if (amount > settings.maxTipAmount) {
    throw new HttpsError(
      "invalid-argument",
      `Maximum tip is ₹${settings.maxTipAmount}.`,
    );
  }
}

export function mergeTipIntoBill(
  bill: Record<string, unknown>,
  tipAmount: number,
): Record<string, unknown> {
  const baseTotal = num(bill.total ?? bill.grandTotal);
  const previousTip = num(bill.deliveryPartnerTip ?? bill.tipAmount);
  const rounded = Math.round((baseTotal - previousTip + tipAmount) * 100) / 100;
  return {
    ...bill,
    deliveryPartnerTip: tipAmount,
    tipAmount,
    total: rounded,
    grandTotal: rounded,
  };
}

function isActiveForTipIncrease(status: string): boolean {
  if (status === OrderStatus.DELIVERED) return false;
  if (status.startsWith("cancelled")) return false;
  return (
    status === OrderStatus.ORDER_PLACED ||
    status === OrderStatus.DELIVERY_ASSIGNED ||
    status === OrderStatus.OUT_FOR_DELIVERY
  );
}

export async function updateOrderTipAmount(
  orderId: string,
  uid: string,
  newTipAmount: number,
  options?: { allowAfterDelivered?: boolean },
): Promise<Record<string, unknown>> {
  const settings = await getDeliveryTipSettings();
  validateTipAmount(newTipAmount, settings);

  const orderRef = db.collection("orders").doc(orderId);
  let previousTip = 0;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(orderRef);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }
    const data = snap.data() as Record<string, unknown>;
    const owner = str(data.uuid);
    if (owner !== uid) {
      throw new HttpsError("permission-denied", "Not your order.");
    }

    if (data.isCancelled === true) {
      throw new HttpsError("failed-precondition", "Order was cancelled.");
    }

    const status = resolveStatus(data);
    const delivered =
      data.isDelivered === true || status === OrderStatus.DELIVERED;
    const allowAfter = options?.allowAfterDelivered === true;

    if (delivered && !allowAfter) {
      throw new HttpsError(
        "failed-precondition",
        "Tips can only be increased while your order is active.",
      );
    }
    if (!delivered && !isActiveForTipIncrease(status)) {
      throw new HttpsError(
        "failed-precondition",
        "Tips can only be updated while your order is active.",
      );
    }

    previousTip = currentTipAmount(data);
    if (newTipAmount <= previousTip) {
      throw new HttpsError(
        "invalid-argument",
        "Tip can only be increased, not reduced.",
      );
    }

    const billRaw = (data.bill ?? {}) as Record<string, unknown>;
    const bill = mergeTipIntoBill(billRaw, newTipAmount);
    const tipStatus = delivered ? "earned" : "pending";

    const patch: Record<string, unknown> = {
      bill,
      tipAmount: newTipAmount,
      tipStatus,
      tipUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (previousTip <= 0) {
      patch.tipAddedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    tx.update(orderRef, patch);
  });

  const updated = await orderRef.get();
  return {
    orderId,
    tipAmount: newTipAmount,
    tipStatus: updated.data()?.tipStatus ?? "pending",
    bill: updated.data()?.bill,
  };
}

export async function markTipEarnedOnDelivered(
  orderId: string,
  data: Record<string, unknown>,
): Promise<void> {
  const tip = currentTipAmount(data);
  if (tip <= 0) return;
  if (str(data.tipStatus) === "earned") return;
  await db.collection("orders").doc(orderId).update({
    tipStatus: "earned",
  });
}
