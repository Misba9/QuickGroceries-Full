import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import {
  CouponErrorCode,
  CouponType,
  COUPON_TYPES,
  normalizePhone,
} from "./coupon_types";

const db = admin.firestore();

export interface CouponDoc {
  id: string;
  code: string;
  coupon_type: CouponType;
  discount: number;
  flat_amount: number;
  minimum_order_amount: number;
  maximum_discount_amount: number;
  first_order_only: boolean;
  free_delivery: boolean;
  is_active: boolean;
  usage_limit: number;
  used_count: number;
  per_user_limit: number;
  applicable_vendor_ids: string[];
  applicable_product_ids: string[];
  applicable_category_ids: string[];
  start_date?: Timestamp;
  expiry_date?: Timestamp;
  one_per_device: boolean;
}

export interface ValidateInput {
  code: string;
  userId?: string;
  phone?: string;
  deviceId?: string;
  subtotal: number;
  vendorIds: string[];
  productIds: string[];
  categoryIds: string[];
}

export interface ValidateSuccess {
  valid: true;
  couponId: string;
  code: string;
  couponType: CouponType;
  discountPercent: number;
  flatAmount: number;
  maxDiscountAmount: number;
  freeDelivery: boolean;
  firstOrderOnly: boolean;
  savingsPreview: number;
  message: string;
}

export interface ValidateFailure {
  valid: false;
  errorCode: CouponErrorCode;
  message: string;
}

export type ValidateResult = ValidateSuccess | ValidateFailure;

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x)).filter(Boolean);
}

export function parseCouponDoc(
  id: string,
  data: admin.firestore.DocumentData
): CouponDoc {
  const legacyDiscount = num(data.discount);
  const typeRaw = str(data.coupon_type) || "percentage_discount";
  const couponType = (COUPON_TYPES.includes(typeRaw as CouponType)
    ? typeRaw
    : legacyDiscount > 0
      ? "percentage_discount"
      : "flat_discount") as CouponType;

  return {
    id,
    code: str(data.code).toUpperCase(),
    coupon_type: couponType,
    discount: num(data.discount),
    flat_amount: num(data.flat_amount),
    minimum_order_amount: num(data.minimum_order_amount ?? data.minOrderValue),
    maximum_discount_amount: num(data.maximum_discount_amount),
    first_order_only:
      data.first_order_only === true ||
      couponType === "first_order",
    free_delivery:
      data.free_delivery === true || couponType === "free_delivery",
    is_active: data.is_active !== false && data.isActive !== false,
    usage_limit: num(data.usage_limit),
    used_count: num(data.used_count),
    per_user_limit: Math.max(1, num(data.per_user_limit, 1)),
    applicable_vendor_ids: strList(
      data.applicable_vendor_ids ?? data.applicableVendorIds
    ),
    applicable_product_ids: strList(
      data.applicable_product_ids ?? data.applicableProductIds
    ),
    applicable_category_ids: strList(
      data.applicable_category_ids ?? data.applicableCategoryIds
    ),
    start_date: data.start_date as Timestamp | undefined,
    expiry_date: (data.expiry_date ?? data.expiresAt) as Timestamp | undefined,
    one_per_device: data.one_per_device === true,
  };
}

export async function findCouponByCode(code: string): Promise<CouponDoc | null> {
  const normalized = code.trim().toUpperCase();
  const snap = await db
    .collection("coupons")
    .where("code", "==", normalized)
    .limit(1)
    .get();
  if (snap.empty) {
    const lower = await db
      .collection("coupons")
      .where("code", "==", code.trim())
      .limit(1)
      .get();
    if (lower.empty) return null;
    const doc = lower.docs[0];
    return parseCouponDoc(doc.id, doc.data());
  }
  const doc = snap.docs[0];
  return parseCouponDoc(doc.id, doc.data());
}

async function countUserOrders(userId: string): Promise<number> {
  const snap = await db
    .collection("orders")
    .where("uuid", "==", userId)
    .limit(25)
    .get();
  return snap.docs.filter((d) => {
    const data = d.data();
    if (data.isCancelled === true) return false;
    const status = str(data.status ?? data.order_status).toLowerCase();
    if (status === "cancelled") return false;
    return true;
  }).length;
}

async function countPhoneOrders(phone: string): Promise<number> {
  const normalized = normalizePhone(phone);
  if (!normalized) return 0;
  const snap = await db.collection("orders").limit(500).get();
  return snap.docs.filter((d) => {
    const data = d.data();
    if (data.isCancelled === true) return false;
    const p = normalizePhone(str(data.phone ?? data.address_snapshot?.mobile));
    return p === normalized;
  }).length;
}

async function countUserCouponUsage(
  couponId: string,
  userId: string
): Promise<number> {
  const snap = await db
    .collection("coupon_usages")
    .where("couponId", "==", couponId)
    .where("userId", "==", userId)
    .where("success", "==", true)
    .get();
  return snap.size;
}

async function countDeviceFirstOrderUsage(
  deviceId: string
): Promise<number> {
  if (!deviceId) return 0;
  const snap = await db
    .collection("coupon_usages")
    .where("deviceId", "==", deviceId)
    .where("firstOrderCoupon", "==", true)
    .where("success", "==", true)
    .limit(1)
    .get();
  return snap.size;
}

function computeSavings(coupon: CouponDoc, subtotal: number): number {
  let discount = 0;
  if (
    coupon.coupon_type === "flat_discount" ||
    (coupon.flat_amount > 0 && coupon.coupon_type !== "free_delivery")
  ) {
    discount = coupon.flat_amount;
  } else if (coupon.discount > 0) {
    discount = subtotal * (coupon.discount / 100);
  }
  if (coupon.maximum_discount_amount > 0) {
    discount = Math.min(discount, coupon.maximum_discount_amount);
  }
  return Math.min(Math.max(0, discount), subtotal);
}

function intersects(applicable: string[], cart: string[]): boolean {
  if (!applicable.length) return true;
  if (!cart.length) return false;
  const set = new Set(cart);
  return applicable.some((id) => set.has(id));
}

export async function validateCoupon(
  input: ValidateInput
): Promise<ValidateResult> {
  const coupon = await findCouponByCode(input.code);
  if (!coupon) {
    return {
      valid: false,
      errorCode: "NOT_FOUND",
      message: "Invalid coupon code",
    };
  }

  if (!coupon.is_active) {
    return {
      valid: false,
      errorCode: "INACTIVE",
      message: "This coupon is not active",
    };
  }

  const now = Date.now();
  if (coupon.start_date && coupon.start_date.toMillis() > now) {
    return {
      valid: false,
      errorCode: "NOT_STARTED",
      message: "This coupon is not valid yet",
    };
  }
  if (coupon.expiry_date && coupon.expiry_date.toMillis() < now) {
    return {
      valid: false,
      errorCode: "EXPIRED",
      message: "Coupon expired",
    };
  }

  if (coupon.usage_limit > 0 && coupon.used_count >= coupon.usage_limit) {
    return {
      valid: false,
      errorCode: "USAGE_LIMIT",
      message: "Coupon usage limit reached",
    };
  }

  if (input.subtotal < coupon.minimum_order_amount) {
    return {
      valid: false,
      errorCode: "MIN_ORDER",
      message: `Minimum order ₹${coupon.minimum_order_amount} required`,
    };
  }

  if (coupon.coupon_type === "vendor_specific" && coupon.applicable_vendor_ids.length) {
    if (!intersects(coupon.applicable_vendor_ids, input.vendorIds)) {
      return {
        valid: false,
        errorCode: "VENDOR_MISMATCH",
        message: "Coupon not valid for items in your cart",
      };
    }
  }

  if (coupon.coupon_type === "product_specific" && coupon.applicable_product_ids.length) {
    if (!intersects(coupon.applicable_product_ids, input.productIds)) {
      return {
        valid: false,
        errorCode: "PRODUCT_MISMATCH",
        message: "Coupon not valid for these products",
      };
    }
  }

  if (coupon.applicable_category_ids.length) {
    if (!intersects(coupon.applicable_category_ids, input.categoryIds)) {
      return {
        valid: false,
        errorCode: "CATEGORY_MISMATCH",
        message: "Coupon not valid for these categories",
      };
    }
  }

  const userId = str(input.userId);
  if (userId) {
    const perUser = await countUserCouponUsage(coupon.id, userId);
    if (perUser >= coupon.per_user_limit) {
      return {
        valid: false,
        errorCode: "PER_USER_LIMIT",
        message: "Coupon already used",
      };
    }
  }

  if (coupon.first_order_only) {
    if (userId) {
      const orders = await countUserOrders(userId);
      if (orders > 0) {
        return {
          valid: false,
          errorCode: "FIRST_ORDER_ONLY",
          message: "Only valid for first order",
        };
      }
    }
    const phone = str(input.phone);
    if (phone) {
      const phoneOrders = await countPhoneOrders(phone);
      if (phoneOrders > 0) {
        return {
          valid: false,
          errorCode: "PHONE_ALREADY_USED",
          message: "This phone number has already placed an order",
        };
      }
    }
    const deviceId = str(input.deviceId);
    if (coupon.one_per_device && deviceId) {
      const deviceUsed = await countDeviceFirstOrderUsage(deviceId);
      if (deviceUsed > 0) {
        return {
          valid: false,
          errorCode: "DEVICE_ALREADY_USED",
          message: "First-order offer already used on this device",
        };
      }
    }
  }

  const savingsPreview = computeSavings(coupon, input.subtotal);
  const discountPercent =
    coupon.coupon_type === "percentage_discount" ||
    (coupon.discount > 0 && coupon.flat_amount <= 0)
      ? coupon.discount
      : 0;

  return {
    valid: true,
    couponId: coupon.id,
    code: coupon.code,
    couponType: coupon.coupon_type,
    discountPercent,
    flatAmount: coupon.flat_amount,
    maxDiscountAmount: coupon.maximum_discount_amount,
    freeDelivery: coupon.free_delivery,
    firstOrderOnly: coupon.first_order_only,
    savingsPreview,
    message: "Coupon applied successfully",
  };
}

export async function logCouponAttempt(opts: {
  couponId: string;
  couponCode: string;
  userId?: string;
  phone?: string;
  deviceId?: string;
  success: boolean;
  errorCode?: CouponErrorCode;
  subtotal?: number;
  discountApplied?: number;
  orderId?: string;
  firstOrderCoupon?: boolean;
}): Promise<void> {
  await db.collection("coupon_usages").add({
    couponId: opts.couponId,
    couponCode: opts.couponCode,
    userId: opts.userId ?? "",
    phone: normalizePhone(opts.phone ?? ""),
    deviceId: opts.deviceId ?? "",
    success: opts.success,
    errorCode: opts.errorCode ?? "",
    subtotal: opts.subtotal ?? 0,
    discountApplied: opts.discountApplied ?? 0,
    orderId: opts.orderId ?? "",
    firstOrderCoupon: opts.firstOrderCoupon === true,
    createdAt: FieldValue.serverTimestamp(),
  });

  const ref = db.collection("coupons").doc(opts.couponId);
  if (opts.success) {
    await ref.update({
      used_count: FieldValue.increment(1),
      analytics_total_usage: FieldValue.increment(1),
      analytics_revenue: FieldValue.increment(opts.discountApplied ?? 0),
      ...(opts.firstOrderCoupon
        ? { analytics_first_order_users: FieldValue.increment(1) }
        : {}),
    });
  } else {
    await ref.update({
      analytics_failed_attempts: FieldValue.increment(1),
    });
  }
}

export async function redeemCoupon(opts: {
  code: string;
  userId: string;
  phone?: string;
  deviceId?: string;
  subtotal: number;
  vendorIds: string[];
  productIds: string[];
  categoryIds: string[];
  orderId: string;
  discountApplied: number;
}): Promise<ValidateResult> {
  const result = await validateCoupon({
    code: opts.code,
    userId: opts.userId,
    phone: opts.phone,
    deviceId: opts.deviceId,
    subtotal: opts.subtotal,
    vendorIds: opts.vendorIds,
    productIds: opts.productIds,
    categoryIds: opts.categoryIds,
  });

  if (!result.valid) {
    const found = await findCouponByCode(opts.code);
    if (found) {
      await logCouponAttempt({
        couponId: found.id,
        couponCode: found.code,
        userId: opts.userId,
        phone: opts.phone,
        deviceId: opts.deviceId,
        success: false,
        errorCode: result.errorCode,
        subtotal: opts.subtotal,
        firstOrderCoupon: found.first_order_only,
      });
    }
    return result;
  }

  await logCouponAttempt({
    couponId: result.couponId,
    couponCode: result.code,
    userId: opts.userId,
    phone: opts.phone,
    deviceId: opts.deviceId,
    success: true,
    subtotal: opts.subtotal,
    discountApplied: opts.discountApplied,
    orderId: opts.orderId,
    firstOrderCoupon: result.firstOrderOnly,
  });

  return result;
}
