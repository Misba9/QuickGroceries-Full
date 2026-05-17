import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import {
  findCouponByCode,
  logCouponAttempt,
  redeemCoupon,
  validateCoupon,
} from "./coupon_engine";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x)).filter(Boolean);
}

/** Validate coupon at checkout (does not increment usage). */
export const validateCouponCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const code = str(req.data?.code);
    if (!code) {
      throw new HttpsError("invalid-argument", "Coupon code is required.");
    }

    const result = await validateCoupon({
      code,
      userId: str(req.auth?.uid),
      phone: str(req.data?.phone),
      deviceId: str(req.data?.deviceId),
      subtotal: num(req.data?.subtotal),
      vendorIds: strList(req.data?.vendorIds),
      productIds: strList(req.data?.productIds),
      categoryIds: strList(req.data?.categoryIds),
    });

    if (!result.valid) {
      const found = await findCouponByCode(code);
      if (found) {
        await logCouponAttempt({
          couponId: found.id,
          couponCode: found.code,
          userId: str(req.auth?.uid),
          phone: str(req.data?.phone),
          deviceId: str(req.data?.deviceId),
          success: false,
          errorCode: result.errorCode,
          subtotal: num(req.data?.subtotal),
          firstOrderCoupon: found.first_order_only,
        });
      }
    }

    return result;
  }
);

/** Redeem coupon when order is placed (increments usage). */
export const redeemCouponCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to use coupons.");
    }

    const code = str(req.data?.code);
    const orderId = str(req.data?.orderId);
    if (!code || !orderId) {
      throw new HttpsError("invalid-argument", "code and orderId are required.");
    }

    const result = await redeemCoupon({
      code,
      userId: uid,
      phone: str(req.data?.phone),
      deviceId: str(req.data?.deviceId),
      subtotal: num(req.data?.subtotal),
      vendorIds: strList(req.data?.vendorIds),
      productIds: strList(req.data?.productIds),
      categoryIds: strList(req.data?.categoryIds),
      orderId,
      discountApplied: num(req.data?.discountApplied),
    });

    return result;
  }
);

/** List active coupons for checkout (lightweight). */
export const listActiveCouponsCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async () => {
    const snap = await admin
      .firestore()
      .collection("coupons")
      .where("is_active", "==", true)
      .limit(50)
      .get();

    const now = Date.now();
    return {
      coupons: snap.docs
        .map((d) => {
          const m = d.data();
          const expiry = m.expiry_date?.toMillis?.() ?? m.expiresAt?.toMillis?.();
          if (expiry && expiry < now) return null;
          return {
            id: d.id,
            code: str(m.code),
            couponType: str(m.coupon_type) || "percentage_discount",
            discount: num(m.discount),
            flatAmount: num(m.flat_amount),
            minimumOrderAmount: num(m.minimum_order_amount ?? m.minOrderValue),
            freeDelivery: m.free_delivery === true,
            firstOrderOnly:
              m.first_order_only === true || m.coupon_type === "first_order",
            description: str(m.description),
          };
        })
        .filter(Boolean),
    };
  }
);
