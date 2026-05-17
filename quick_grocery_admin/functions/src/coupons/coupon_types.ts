export const COUPON_TYPES = [
  "first_order",
  "special_offer",
  "festival_offer",
  "free_delivery",
  "percentage_discount",
  "flat_discount",
  "vendor_specific",
  "product_specific",
] as const;

export type CouponType = (typeof COUPON_TYPES)[number];

export type CouponErrorCode =
  | "NOT_FOUND"
  | "INACTIVE"
  | "EXPIRED"
  | "NOT_STARTED"
  | "USAGE_LIMIT"
  | "PER_USER_LIMIT"
  | "MIN_ORDER"
  | "FIRST_ORDER_ONLY"
  | "PHONE_ALREADY_USED"
  | "DEVICE_ALREADY_USED"
  | "VENDOR_MISMATCH"
  | "PRODUCT_MISMATCH"
  | "CATEGORY_MISMATCH"
  | "INVALID_TYPE";

export function normalizePhone(phone: string): string {
  const digits = phone.replace(/\D/g, "");
  if (digits.length >= 10) return digits.slice(-10);
  return digits;
}

export function couponTypeLabel(type: string): string {
  switch (type) {
    case "first_order":
      return "First Order";
    case "special_offer":
      return "Special Offer";
    case "festival_offer":
      return "Festival Offer";
    case "free_delivery":
      return "Free Delivery";
    case "percentage_discount":
      return "Percentage Discount";
    case "flat_discount":
      return "Flat Discount";
    case "vendor_specific":
      return "Vendor Specific";
    case "product_specific":
      return "Product Specific";
    default:
      return type;
  }
}
