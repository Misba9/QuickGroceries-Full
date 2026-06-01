import * as crypto from "crypto";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import * as admin from "firebase-admin";
import { otpPepper } from "../partner_auth/partner_crypto";
import { notifyCustomer, num, str } from "./ops_notify";

const db = admin.firestore();

export const DELIVERY_OTP_EXPIRY_MS = 3 * 60 * 60 * 1000;
export const MAX_DELIVERY_OTP_ATTEMPTS = 5;

/** 4-digit code — easy for customer to read and rider to enter. */
export function generateDeliveryOtp(): string {
  return crypto.randomInt(1000, 10000).toString();
}

export function hashDeliveryOtp(otp: string, orderId: string): string {
  return crypto
    .createHmac("sha256", otpPepper())
    .update(`delivery:${orderId}:${otp.trim()}`)
    .digest("hex");
}

export function verifyDeliveryOtp(
  order: Record<string, unknown>,
  otp: string,
  orderId: string
): { ok: true } | { ok: false; reason: string } {
  const expiry = order.deliveryOtpExpiry ?? order.delivery_otp_expiry;
  if (expiry instanceof Timestamp && expiry.toMillis() < Date.now()) {
    return { ok: false, reason: "This delivery code has expired." };
  }

  const attempts = Number(order.deliveryOtpAttempts ?? order.delivery_otp_attempts ?? 0);
  if (attempts >= MAX_DELIVERY_OTP_ATTEMPTS) {
    return {
      ok: false,
      reason: "Too many incorrect attempts. Contact support.",
    };
  }

  const expected = str(order.deliveryOtpHash ?? order.delivery_otp_hash);
  if (!expected) {
    return { ok: false, reason: "Delivery code not issued yet." };
  }

  const provided = hashDeliveryOtp(otp, orderId);
  if (expected !== provided) {
    return { ok: false, reason: "Invalid delivery code." };
  }

  return { ok: true };
}

/** Issue OTP when rider starts customer delivery leg (`out_for_delivery`). */
export async function issueDeliveryOtp(
  orderId: string,
  order: Record<string, unknown>,
  customerUid: string
): Promise<void> {
  const otp = generateDeliveryOtp();
  const hash = hashDeliveryOtp(otp, orderId);
  const expiry = Timestamp.fromMillis(Date.now() + DELIVERY_OTP_EXPIRY_MS);

  await db.collection("orders").doc(orderId).update({
    deliveryOtpHash: hash,
    delivery_otp_hash: hash,
    deliveryOtpExpiry: expiry,
    delivery_otp_expiry: expiry,
    deliveryOtpAttempts: 0,
    delivery_otp_attempts: 0,
    deliveryOtpIssuedAt: FieldValue.serverTimestamp(),
    delivery_otp_issued_at: FieldValue.serverTimestamp(),
  });

  if (customerUid) {
    await db
      .collection("customers")
      .doc(customerUid)
      .collection("delivery_otps")
      .doc(orderId)
      .set({
        otp,
        orderId,
        expiry,
        createdAt: FieldValue.serverTimestamp(),
      });

    await notifyCustomer(customerUid, {
      title: "Delivery OTP",
      body: `Your delivery code is ${otp}. Share it with the rider when they arrive.`,
      type: "delivery_otp",
      deepLink: `/orders/${orderId}`,
      orderId,
      extraData: { otp, orderId },
    });
  }

  if (process.env.FUNCTIONS_EMULATOR === "true") {
    console.log(`[delivery_otp] order=${orderId} otp=${otp}`);
  }
}

export async function clearDeliveryOtp(
  orderId: string,
  customerUid: string
): Promise<void> {
  await db.collection("orders").doc(orderId).update({
    deliveryOtpHash: FieldValue.delete(),
    delivery_otp_hash: FieldValue.delete(),
    deliveryOtpExpiry: FieldValue.delete(),
    delivery_otp_expiry: FieldValue.delete(),
    deliveryOtpAttempts: FieldValue.delete(),
    delivery_otp_attempts: FieldValue.delete(),
    deliveryOtpIssuedAt: FieldValue.delete(),
    delivery_otp_issued_at: FieldValue.delete(),
    deliveryOtpVerifiedAt: FieldValue.serverTimestamp(),
    delivery_otp_verified_at: FieldValue.serverTimestamp(),
  });

  if (customerUid) {
    await db
      .collection("customers")
      .doc(customerUid)
      .collection("delivery_otps")
      .doc(orderId)
      .delete()
      .catch(() => undefined);
  }
}

export function orderEarning(data: Record<string, unknown>): number {
  const deliveryCharge = num(data.deliveryCharge ?? data.delivery_charge);
  if (deliveryCharge > 0) return deliveryCharge;

  const bill = data.bill as Record<string, unknown> | undefined;
  if (bill?.deliveryFee != null) return num(bill.deliveryFee);

  const products = (data.products as unknown[]) || [];
  let subtotal = 0;
  for (const raw of products) {
    const p = raw as Record<string, unknown>;
    subtotal +=
      num(p.price) * num(p.itemCount ?? p.quantity ?? p.item_count ?? 1);
  }
  return subtotal * 0.05;
}
