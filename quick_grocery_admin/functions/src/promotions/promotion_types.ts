import type { Timestamp, FieldValue } from "firebase-admin/firestore";

/** Supported product promotion types (admin-controlled). */
export const PROMOTION_TYPES = [
  "flash_sale",
  "todays_deal",
  "featured",
  "best_seller",
  "recommended",
  "trending",
  "new_arrival",
  "limited_time",
  "discount_badge",
  "bogo",
  "combo_offer",
] as const;

export type PromotionType = (typeof PROMOTION_TYPES)[number];

export type PromotionSource = "admin" | "vendor";

export type PromotionRequestStatus = "pending" | "approved" | "rejected";

export interface ProductPromotion {
  id?: string;
  productId: string;
  productName?: string;
  vendorId?: string;
  vendorName?: string;
  promotionType: PromotionType;
  enabled: boolean;
  salePrice: number | null;
  discountPercent: number | null;
  startDate: Timestamp | Date | null;
  endDate: Timestamp | Date | null;
  badge: string;
  bannerLabel: string;
  priority: number;
  maxPurchase: number;
  stockLimit: number;
  pinToTop: boolean;
  visible: boolean;
  locked: boolean;
  expired: boolean;
  source: PromotionSource;
  createdBy: string;
  updatedBy: string;
  reason?: string;
  createdAt?: FieldValue | Timestamp;
  updatedAt?: FieldValue | Timestamp;
}

export interface PromotionInput {
  productId: string;
  promotionType: PromotionType;
  enabled?: boolean;
  salePrice?: number | null;
  discountPercent?: number | null;
  startDate?: string | number | Date | null;
  endDate?: string | number | Date | null;
  badge?: string;
  bannerLabel?: string;
  priority?: number;
  maxPurchase?: number;
  stockLimit?: number;
  pinToTop?: boolean;
  visible?: boolean;
  locked?: boolean;
  source?: PromotionSource;
  reason?: string;
}

export interface ProductPromotionPatch {
  flags?: Partial<Record<PromotionType, boolean>>;
  salePrice?: number | null;
  discountPercent?: number | null;
  flashSaleStart?: string | number | Date | null;
  flashSaleEnd?: string | number | Date | null;
  offerExpiry?: string | number | Date | null;
  stockLimit?: number | null;
  maxPurchase?: number | null;
  visible?: boolean;
  pinToTop?: boolean;
  bannerLabel?: string;
  badge?: string;
  locked?: boolean;
  reason?: string;
}

export function isPromotionType(v: unknown): v is PromotionType {
  return typeof v === "string" && (PROMOTION_TYPES as readonly string[]).includes(v);
}
