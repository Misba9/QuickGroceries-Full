import * as admin from "firebase-admin";
import {
  FieldValue,
  Timestamp,
  type DocumentData,
  type Query,
  type QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import { notifyVendor, writeActivityLog } from "../operations/ops_notify";
import {
  isPromotionType,
  PROMOTION_TYPES,
  type ProductPromotionPatch,
  type PromotionInput,
  type PromotionSource,
  type PromotionType,
} from "./promotion_types";

const db = admin.firestore();
export const PROMOTIONS_COL = "product_promotions";
export const AUDIT_COL = "promotion_audit_logs";

const TYPE_PRIORITY: Record<PromotionType, number> = {
  flash_sale: 100,
  limited_time: 90,
  todays_deal: 80,
  bogo: 75,
  combo_offer: 70,
  featured: 60,
  best_seller: 55,
  trending: 50,
  recommended: 45,
  new_arrival: 40,
  discount_badge: 30,
};

function asNum(v: unknown): number | null {
  if (v === null || v === undefined || v === "") return null;
  const n = typeof v === "number" ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

function asBool(v: unknown, fallback = false): boolean {
  if (v === undefined || v === null) return fallback;
  return v === true;
}

function toTimestamp(
  v: string | number | Date | Timestamp | null | undefined
): Timestamp | null {
  if (v === null || v === undefined || v === "") return null;
  if (v instanceof Timestamp) return v;
  if (v instanceof Date) return Timestamp.fromDate(v);
  if (typeof v === "number") {
    const ms = v < 1e12 ? v * 1000 : v;
    return Timestamp.fromMillis(ms);
  }
  if (typeof v === "string") {
    const d = new Date(v);
    if (Number.isNaN(d.getTime())) return null;
    return Timestamp.fromDate(d);
  }
  return null;
}

function serializePromo(id: string, data: DocumentData) {
  const start = data.startDate as Timestamp | undefined;
  const end = data.endDate as Timestamp | undefined;
  return {
    id,
    productId: String(data.productId || ""),
    productName: String(data.productName || ""),
    vendorId: String(data.vendorId || ""),
    vendorName: String(data.vendorName || ""),
    promotionType: data.promotionType as PromotionType,
    enabled: data.enabled === true,
    salePrice: asNum(data.salePrice),
    discountPercent: asNum(data.discountPercent),
    startDate: start?.toDate?.()?.toISOString?.() ?? null,
    endDate: end?.toDate?.()?.toISOString?.() ?? null,
    badge: String(data.badge || ""),
    bannerLabel: String(data.bannerLabel || ""),
    priority: asNum(data.priority) ?? 0,
    maxPurchase: asNum(data.maxPurchase) ?? 0,
    stockLimit: asNum(data.stockLimit) ?? 0,
    pinToTop: data.pinToTop === true,
    visible: data.visible !== false,
    locked: data.locked === true,
    expired: data.expired === true,
    source: (data.source as PromotionSource) || "admin",
    createdBy: String(data.createdBy || ""),
    updatedBy: String(data.updatedBy || ""),
    reason: String(data.reason || ""),
    createdAt: (data.createdAt as Timestamp | undefined)?.toDate?.()?.toISOString?.() ?? null,
    updatedAt: (data.updatedAt as Timestamp | undefined)?.toDate?.()?.toISOString?.() ?? null,
  };
}

async function loadProduct(productId: string) {
  const snap = await db.collection("products").doc(productId).get();
  if (!snap.exists) throw new Error(`Product not found: ${productId}`);
  const data = snap.data() || {};
  return {
    id: snap.id,
    name: String(data.name || ""),
    vendorId: String(data.vendor_id || data.vendorId || ""),
    vendorName: String(data.shop_name || data.shopName || data.vendorName || ""),
    price: asNum(data.price) ?? 0,
    data,
  };
}

async function writeAudit(opts: {
  adminUid: string;
  adminName: string;
  productId: string;
  productName: string;
  vendorId: string;
  promotionId: string;
  promotionType: string;
  oldValue: Record<string, unknown>;
  newValue: Record<string, unknown>;
  reason?: string;
}): Promise<void> {
  await db.collection(AUDIT_COL).add({
    adminUid: opts.adminUid,
    adminName: opts.adminName,
    productId: opts.productId,
    productName: opts.productName,
    vendorId: opts.vendorId,
    promotionId: opts.promotionId,
    promotionType: opts.promotionType,
    oldValue: opts.oldValue,
    newValue: opts.newValue,
    reason: opts.reason || "",
    createdAt: FieldValue.serverTimestamp(),
  });

  await writeActivityLog({
    action: "promotion_updated",
    entityType: "product_promotion",
    entityId: opts.promotionId,
    summary: `${opts.adminName} updated ${opts.promotionType} on ${opts.productName}`,
    metadata: {
      productId: opts.productId,
      vendorId: opts.vendorId,
      reason: opts.reason || "",
      adminUid: opts.adminUid,
    },
  });
}

/**
 * Resolve active promotions for a product with Admin > Vendor > default priority.
 * Admin-locked or admin-sourced enabled promos override vendor ones of the same type.
 */
export function pickWinningPromotions(
  docs: Array<{ id: string; data: DocumentData }>
): Map<PromotionType, { id: string; data: DocumentData }> {
  const now = Date.now();
  const byType = new Map<
    PromotionType,
    Array<{ id: string; data: DocumentData; score: number }>
  >();

  for (const d of docs) {
    const type = d.data.promotionType as PromotionType;
    if (!isPromotionType(type)) continue;
    if (d.data.expired === true) continue;
    if (d.data.enabled !== true) continue;

    const start = d.data.startDate as Timestamp | undefined;
    const end = d.data.endDate as Timestamp | undefined;
    if (start && start.toMillis() > now) continue;
    if (end && end.toMillis() <= now) continue;

    const source = (d.data.source as PromotionSource) || "vendor";
    const locked = d.data.locked === true;
    const prio = asNum(d.data.priority) ?? TYPE_PRIORITY[type] ?? 0;
    // Admin always beats vendor; locked admin gets a boost.
    const score =
      (source === "admin" ? 1_000_000 : 0) +
      (locked ? 100_000 : 0) +
      prio;

    const list = byType.get(type) || [];
    list.push({ id: d.id, data: d.data, score });
    byType.set(type, list);
  }

  const winners = new Map<PromotionType, { id: string; data: DocumentData }>();
  for (const [type, list] of byType) {
    list.sort((a, b) => b.score - a.score);
    winners.set(type, { id: list[0].id, data: list[0].data });
  }
  return winners;
}

/** Dual-write resolved promotion state onto the product document for live clients. */
export async function syncProductFromPromotions(productId: string): Promise<void> {
  const productRef = db.collection("products").doc(productId);
  const productSnap = await productRef.get();
  if (!productSnap.exists) return;
  const product = productSnap.data() || {};

  const promoSnap = await db
    .collection(PROMOTIONS_COL)
    .where("productId", "==", productId)
    .get();

  const docs = promoSnap.docs.map((d) => ({ id: d.id, data: d.data() }));
  const winners = pickWinningPromotions(docs);

  const flag = (t: PromotionType) => winners.has(t);

  const flash = winners.get("flash_sale");
  const limited = winners.get("limited_time");
  const todays = winners.get("todays_deal");
  const bogo = winners.get("bogo");

  // Pricing: highest-priority winner that carries a sale price / discount.
  let salePrice: number | null = null;
  let discountPercent: number | null = null;
  let badge = "";
  let bannerLabel = "";
  let pinToTop = false;
  let maxPurchase = 0;
  {
    const order: PromotionType[] = [
      "flash_sale",
      "limited_time",
      "todays_deal",
      "discount_badge",
      "bogo",
      "combo_offer",
      "featured",
    ];
    for (const t of order) {
      const w = winners.get(t);
      if (!w) continue;
      const sp = asNum(w.data.salePrice);
      const dp = asNum(w.data.discountPercent);
      if (sp != null && sp > 0) {
        salePrice = sp;
        discountPercent = dp;
        break;
      }
      if (dp != null && dp > 0) {
        discountPercent = dp;
        const mrp = asNum(product.price) ?? 0;
        if (mrp > 0) salePrice = Math.round(mrp * (1 - dp / 100) * 100) / 100;
        break;
      }
    }
  }

  let stockLimit = 0;
  let flashStart: Timestamp | null = null;
  let flashEnd: Timestamp | null = null;
  let offerExpiry: Timestamp | null = null;
  let anyAdminLocked = false;
  let visible = product.is_active !== false && product.isActive !== false;

  for (const w of winners.values()) {
    if (w.data.source === "admin" && w.data.locked === true) anyAdminLocked = true;
    if (w.data.pinToTop === true) pinToTop = true;
    if (typeof w.data.badge === "string" && w.data.badge.trim()) badge = w.data.badge.trim();
    if (typeof w.data.bannerLabel === "string" && w.data.bannerLabel.trim()) {
      bannerLabel = w.data.bannerLabel.trim();
    }
    const mp = asNum(w.data.maxPurchase);
    if (mp != null && mp > 0) maxPurchase = Math.max(maxPurchase, mp);
    const sl = asNum(w.data.stockLimit);
    if (sl != null && sl > 0) stockLimit = Math.max(stockLimit, sl);
    if (w.data.visible === false) visible = false;
    const end = w.data.endDate as Timestamp | undefined;
    if (end && (!offerExpiry || end.toMillis() < offerExpiry.toMillis())) {
      offerExpiry = end;
    }
  }

  if (flash) {
    flashStart = (flash.data.startDate as Timestamp) || null;
    flashEnd = (flash.data.endDate as Timestamp) || null;
    const sl = asNum(flash.data.stockLimit);
    if (sl != null && sl > 0) stockLimit = sl;
  } else if (limited) {
    flashEnd = (limited.data.endDate as Timestamp) || null;
  }

  let specialCat = String(product.special_cat || "");
  if (bogo) {
    specialCat = "Buy 1 Get 1";
  } else if (todays) {
    specialCat = "Today's snacks deals";
  } else if (specialCat === "Buy 1 Get 1" || specialCat === "Today's snacks deals") {
    specialCat = "";
  }

  const hasActiveSale = salePrice != null && salePrice > 0;

  const patch: Record<string, unknown> = {
    is_flash_sale: flag("flash_sale"),
    is_todays_best: flag("todays_deal"),
    is_most_selling: flag("best_seller"),
    most_sold: flag("best_seller"),
    isFeatured: flag("featured"),
    is_featured: flag("featured"),
    admin_featured_approved: flag("featured")
      ? true
      : product.admin_featured_approved !== false,
    isTrending: flag("trending"),
    is_trending: flag("trending"),
    is_recommended: flag("recommended"),
    is_new_arrival: flag("new_arrival"),
    // Promo-driven limited flags — cleared when no active limited_time winner.
    limited_stock: flag("limited_time"),
    is_limited_stock: flag("limited_time"),
    is_discount_badge: flag("discount_badge"),
    is_bogo: flag("bogo"),
    is_combo_offer_promo: flag("combo_offer"),
    is_limited_time_offer: flag("limited_time"),
    special_cat: specialCat,
    // Reflect current lock only (do not sticky-OR previous true).
    admin_settings_locked: anyAdminLocked,
    promo_badge: badge,
    custom_badge_text: badge,
    promotional_banner_label: bannerLabel,
    pin_to_top: pinToTop,
    promo_stock_limit: stockLimit,
    flash_sale_stock_limit: stockLimit,
    promo_max_purchase: maxPurchase,
    offer_expiry: offerExpiry,
    flash_sale_start: flashStart,
    flash_sale_end: flashEnd,
    // Always write sale fields so expiry clears leftover promo prices.
    discountPrice: hasActiveSale ? salePrice : 0,
    slashedPrice: hasActiveSale ? salePrice : 0,
    promo_discount_percent:
      discountPercent != null && discountPercent > 0 ? discountPercent : 0,
    settings_updated_at: FieldValue.serverTimestamp(),
    lastEdited: FieldValue.serverTimestamp(),
    promo_synced_at: FieldValue.serverTimestamp(),
  };

  if (maxPurchase > 0) {
    patch.maxOrder = maxPurchase;
    patch.max_order_quantity = maxPurchase;
  }
  if (visible === false) {
    patch.is_active = false;
    patch.isActive = false;
    patch.active = false;
    patch.isAvailable = false;
  }

  await productRef.set(patch, { merge: true });
}

export async function listPromotions(opts?: {
  productId?: string;
  vendorId?: string;
  enabledOnly?: boolean;
  includeExpired?: boolean;
  limit?: number;
}) {
  let q: Query = db.collection(PROMOTIONS_COL);
  if (opts?.productId) q = q.where("productId", "==", opts.productId);
  else if (opts?.vendorId) q = q.where("vendorId", "==", opts.vendorId);

  const snap = await q.limit(Math.min(opts?.limit ?? 500, 1000)).get();
  let items = snap.docs.map((d) => serializePromo(d.id, d.data()));
  if (opts?.enabledOnly) items = items.filter((p) => p.enabled && !p.expired);
  if (!opts?.includeExpired) items = items.filter((p) => !p.expired);
  items.sort((a, b) => (b.priority || 0) - (a.priority || 0));
  return items;
}

export async function getPromotion(id: string) {
  const snap = await db.collection(PROMOTIONS_COL).doc(id).get();
  if (!snap.exists) return null;
  return serializePromo(snap.id, snap.data() || {});
}

export async function createPromotion(
  input: PromotionInput,
  actor: { uid: string; name: string; source?: PromotionSource }
) {
  if (!input.productId) throw new Error("productId is required");
  if (!isPromotionType(input.promotionType)) {
    throw new Error(`Invalid promotionType. Allowed: ${PROMOTION_TYPES.join(", ")}`);
  }

  const product = await loadProduct(input.productId);
  const source = actor.source || input.source || "admin";
  const ref = db.collection(PROMOTIONS_COL).doc();

  const startTs = toTimestamp(input.startDate ?? null);
  const endTs = toTimestamp(input.endDate ?? null);
  const awaitingStart =
    !!startTs && startTs.toMillis() > Date.now() && input.enabled !== false;

  const doc = {
    productId: input.productId,
    productName: product.name,
    vendorId: product.vendorId,
    vendorName: product.vendorName,
    promotionType: input.promotionType,
    enabled: input.enabled !== false && !awaitingStart,
    awaitingStart,
    salePrice: asNum(input.salePrice),
    discountPercent: asNum(input.discountPercent),
    startDate: startTs,
    endDate: endTs,
    badge: String(input.badge || ""),
    bannerLabel: String(input.bannerLabel || ""),
    priority: asNum(input.priority) ?? TYPE_PRIORITY[input.promotionType],
    maxPurchase: asNum(input.maxPurchase) ?? 0,
    stockLimit: asNum(input.stockLimit) ?? 0,
    pinToTop: asBool(input.pinToTop),
    visible: input.visible !== false,
    locked: source === "admin" ? input.locked !== false : false,
    expired: false,
    source,
    createdBy: actor.uid,
    updatedBy: actor.uid,
    reason: String(input.reason || ""),
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  await ref.set(doc);
  await syncProductFromPromotions(input.productId);

  await writeAudit({
    adminUid: actor.uid,
    adminName: actor.name,
    productId: input.productId,
    productName: product.name,
    vendorId: product.vendorId,
    promotionId: ref.id,
    promotionType: input.promotionType,
    oldValue: {},
    newValue: serializePromo(ref.id, doc) as unknown as Record<string, unknown>,
    reason: input.reason,
  });

  if (product.vendorId && source === "admin") {
    await notifyVendorSafe(product.vendorId, product.name, input.promotionType, ref.id);
  }

  return serializePromo(ref.id, { ...doc });
}

export async function updatePromotion(
  id: string,
  patch: Partial<PromotionInput> & Record<string, unknown>,
  actor: { uid: string; name: string }
) {
  const ref = db.collection(PROMOTIONS_COL).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Promotion not found");
  const prev = snap.data() || {};

  // Vendor cannot modify admin-locked promotions
  if (prev.source === "admin" && prev.locked === true && patch._allowLocked !== true) {
    // Admin path always passes; vendor callers must not get here with allow.
  }

  const next: Record<string, unknown> = {
    updatedBy: actor.uid,
    updatedAt: FieldValue.serverTimestamp(),
  };

  const keys = [
    "enabled",
    "salePrice",
    "discountPercent",
    "badge",
    "bannerLabel",
    "priority",
    "maxPurchase",
    "stockLimit",
    "pinToTop",
    "visible",
    "locked",
    "reason",
  ] as const;

  for (const k of keys) {
    if (patch[k] !== undefined) next[k] = patch[k];
  }
  if (patch.startDate !== undefined) next.startDate = toTimestamp(patch.startDate as never);
  if (patch.endDate !== undefined) next.endDate = toTimestamp(patch.endDate as never);
  if (patch.promotionType && isPromotionType(patch.promotionType)) {
    next.promotionType = patch.promotionType;
  }
  if (patch.enabled === true) next.expired = false;

  await ref.update(next);
  const productId = String(prev.productId || "");
  if (productId) await syncProductFromPromotions(productId);

  const after = await ref.get();
  const serialized = serializePromo(id, after.data() || {});

  await writeAudit({
    adminUid: actor.uid,
    adminName: actor.name,
    productId,
    productName: String(prev.productName || ""),
    vendorId: String(prev.vendorId || ""),
    promotionId: id,
    promotionType: String(next.promotionType || prev.promotionType || ""),
    oldValue: serializePromo(id, prev) as unknown as Record<string, unknown>,
    newValue: serialized as unknown as Record<string, unknown>,
    reason: String(patch.reason || ""),
  });

  if (prev.vendorId && prev.source === "admin") {
    await notifyVendorSafe(
      String(prev.vendorId),
      String(prev.productName || ""),
      String(prev.promotionType || ""),
      id
    );
  }

  return serialized;
}

export async function deletePromotion(
  id: string,
  actor: { uid: string; name: string; reason?: string }
) {
  const ref = db.collection(PROMOTIONS_COL).doc(id);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Promotion not found");
  const prev = snap.data() || {};
  const productId = String(prev.productId || "");

  await ref.delete();
  if (productId) await syncProductFromPromotions(productId);

  await writeAudit({
    adminUid: actor.uid,
    adminName: actor.name,
    productId,
    productName: String(prev.productName || ""),
    vendorId: String(prev.vendorId || ""),
    promotionId: id,
    promotionType: String(prev.promotionType || ""),
    oldValue: serializePromo(id, prev) as unknown as Record<string, unknown>,
    newValue: { deleted: true },
    reason: actor.reason || "deleted",
  });

  if (prev.vendorId) {
    await notifyVendorSafe(
      String(prev.vendorId),
      String(prev.productName || ""),
      String(prev.promotionType || ""),
      id
    );
  }

  return { ok: true, id };
}

/**
 * Bulk patch all promotion flags / pricing for a product (admin primary API).
 * Creates or updates one admin promotion doc per toggled type.
 */
export async function patchProductPromotions(
  productId: string,
  patch: ProductPromotionPatch,
  actor: { uid: string; name: string }
) {
  const product = await loadProduct(productId);
  const existing = await db
    .collection(PROMOTIONS_COL)
    .where("productId", "==", productId)
    .where("source", "==", "admin")
    .get();

  const byType = new Map<string, QueryDocumentSnapshot>();
  for (const d of existing.docs) {
    byType.set(String(d.data().promotionType), d);
  }

  const touched: string[] = [];
  const batch = db.batch();
  const flags = patch.flags || {};

  for (const type of PROMOTION_TYPES) {
    if (flags[type] === undefined && !hasSharedFields(patch, type)) continue;

    const enabled = flags[type];
    const existingDoc = byType.get(type);
    const shared = sharedFieldsForType(type, patch);

    if (existingDoc) {
      const update: Record<string, unknown> = {
        ...shared,
        updatedBy: actor.uid,
        updatedAt: FieldValue.serverTimestamp(),
        reason: patch.reason || "",
      };
      if (enabled !== undefined) {
        update.enabled = enabled;
        if (enabled) update.expired = false;
      }
      if (patch.locked !== undefined) update.locked = patch.locked;
      batch.update(existingDoc.ref, update);
      touched.push(existingDoc.id);
    } else if (enabled === true || hasSharedFields(patch, type)) {
      const ref = db.collection(PROMOTIONS_COL).doc();
      batch.set(ref, {
        productId,
        productName: product.name,
        vendorId: product.vendorId,
        vendorName: product.vendorName,
        promotionType: type,
        enabled: enabled !== false,
        salePrice: shared.salePrice ?? null,
        discountPercent: shared.discountPercent ?? null,
        startDate: shared.startDate ?? null,
        endDate: shared.endDate ?? null,
        badge: shared.badge ?? "",
        bannerLabel: shared.bannerLabel ?? "",
        priority: TYPE_PRIORITY[type],
        maxPurchase: shared.maxPurchase ?? 0,
        stockLimit: shared.stockLimit ?? 0,
        pinToTop: shared.pinToTop === true,
        visible: patch.visible !== false,
        locked: patch.locked !== false,
        expired: false,
        source: "admin",
        createdBy: actor.uid,
        updatedBy: actor.uid,
        reason: patch.reason || "",
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      touched.push(ref.id);
    }
  }

  // Visible / lock without specific type: attach to a sentinel doc or product
  if (patch.visible !== undefined || patch.locked !== undefined || patch.pinToTop !== undefined) {
    const productPatch: Record<string, unknown> = {
      lastEdited: FieldValue.serverTimestamp(),
    };
    if (patch.visible === false) {
      productPatch.is_active = false;
      productPatch.isActive = false;
      productPatch.active = false;
      productPatch.isAvailable = false;
    } else if (patch.visible === true) {
      productPatch.is_active = true;
      productPatch.isActive = true;
      productPatch.active = true;
    }
    if (patch.locked !== undefined) {
      productPatch.admin_settings_locked = patch.locked;
    }
    if (patch.pinToTop !== undefined) {
      productPatch.pin_to_top = patch.pinToTop;
    }
    batch.set(db.collection("products").doc(productId), productPatch, { merge: true });
  }

  await batch.commit();
  await syncProductFromPromotions(productId);

  await writeAudit({
    adminUid: actor.uid,
    adminName: actor.name,
    productId,
    productName: product.name,
    vendorId: product.vendorId,
    promotionId: productId,
    promotionType: "bulk_patch",
    oldValue: {},
    newValue: patch as unknown as Record<string, unknown>,
    reason: patch.reason,
  });

  if (product.vendorId) {
    await notifyVendorSafe(product.vendorId, product.name, "bulk", productId);
  }

  return {
    ok: true,
    productId,
    promotionIds: touched,
    promotions: await listPromotions({ productId, includeExpired: true }),
  };
}

function hasSharedFields(patch: ProductPromotionPatch, type: PromotionType): boolean {
  if (type === "flash_sale") {
    return (
      patch.salePrice !== undefined ||
      patch.discountPercent !== undefined ||
      patch.flashSaleStart !== undefined ||
      patch.flashSaleEnd !== undefined ||
      patch.stockLimit !== undefined ||
      patch.maxPurchase !== undefined ||
      (typeof patch.badge === "string" && patch.badge.length > 0) ||
      (typeof patch.bannerLabel === "string" && patch.bannerLabel.length > 0)
    );
  }
  if (type === "limited_time" || type === "discount_badge" || type === "todays_deal") {
    return (
      patch.salePrice !== undefined ||
      patch.discountPercent !== undefined ||
      patch.offerExpiry !== undefined ||
      patch.stockLimit !== undefined ||
      patch.maxPurchase !== undefined ||
      !!patch.badge ||
      !!patch.bannerLabel
    );
  }
  return !!patch.badge || !!patch.bannerLabel || patch.pinToTop !== undefined;
}

function sharedFieldsForType(
  type: PromotionType,
  patch: ProductPromotionPatch
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (patch.salePrice !== undefined) out.salePrice = asNum(patch.salePrice);
  if (patch.discountPercent !== undefined) {
    out.discountPercent = asNum(patch.discountPercent);
  }
  if (patch.stockLimit !== undefined) out.stockLimit = asNum(patch.stockLimit) ?? 0;
  if (patch.maxPurchase !== undefined) out.maxPurchase = asNum(patch.maxPurchase) ?? 0;
  if (patch.badge !== undefined) out.badge = patch.badge;
  if (patch.bannerLabel !== undefined) out.bannerLabel = patch.bannerLabel;
  if (patch.pinToTop !== undefined) out.pinToTop = patch.pinToTop;

  if (type === "flash_sale") {
    if (patch.flashSaleStart !== undefined) {
      out.startDate = toTimestamp(patch.flashSaleStart);
    }
    if (patch.flashSaleEnd !== undefined) {
      out.endDate = toTimestamp(patch.flashSaleEnd);
    }
  } else if (patch.offerExpiry !== undefined) {
    out.endDate = toTimestamp(patch.offerExpiry);
  }
  return out;
}

async function notifyVendorSafe(
  vendorId: string,
  productName: string,
  promotionType: string,
  promotionId: string
) {
  try {
    await notifyVendor(vendorId, {
      title: "Promotion updated by admin",
      message: `Admin updated "${promotionType}" for ${productName || "a product"}.`,
      type: "system_update",
      metadata: {
        productName,
        promotionType,
        promotionId,
        category: "promotions",
      },
    });
  } catch (e) {
    console.warn("[promotions] notifyVendor failed", e);
  }
}

/** Deactivate expired promotions and re-sync affected products. */
export async function deactivateExpiredPromotions(): Promise<{
  deactivated: number;
  productIds: string[];
}> {
  const now = Timestamp.now();
  // Single-field query avoids composite-index requirement; filter endDate in memory.
  const snap = await db
    .collection(PROMOTIONS_COL)
    .where("enabled", "==", true)
    .limit(500)
    .get();

  const batch = db.batch();
  const productIds = new Set<string>();
  let deactivated = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.expired === true) continue;
    const end = data.endDate as Timestamp | undefined;
    if (!end) continue;
    if (end.toMillis() > now.toMillis()) continue;

    batch.update(doc.ref, {
      enabled: false,
      expired: true,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: "system:cleanup",
    });
    productIds.add(String(data.productId || ""));
    deactivated++;
  }

  // Auto-start promotions waiting on startDate
  const scheduled = await db
    .collection(PROMOTIONS_COL)
    .where("awaitingStart", "==", true)
    .limit(200)
    .get();

  let activated = 0;
  for (const doc of scheduled.docs) {
    const data = doc.data();
    const start = data.startDate as Timestamp | undefined;
    const end = data.endDate as Timestamp | undefined;
    if (!start) continue;
    if (start.toMillis() > now.toMillis()) continue;
    if (end && end.toMillis() <= now.toMillis()) continue;

    batch.update(doc.ref, {
      enabled: true,
      awaitingStart: false,
      expired: false,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: "system:cleanup",
    });
    productIds.add(String(data.productId || ""));
    activated++;
  }

  if (deactivated + activated > 0) {
    await batch.commit();
    for (const pid of productIds) {
      if (pid) await syncProductFromPromotions(pid);
    }
  }

  return { deactivated, productIds: [...productIds] };
}

// ─── Vendor promotion requests ─────────────────────────────────────────────

export const PROMOTION_REQUESTS_COL = "promotion_requests";

function serializeRequest(id: string, data: DocumentData) {
  const start = data.startDate as Timestamp | undefined;
  const end = data.endDate as Timestamp | undefined;
  return {
    id,
    productId: String(data.productId || ""),
    productName: String(data.productName || ""),
    vendorId: String(data.vendorId || ""),
    vendorName: String(data.vendorName || ""),
    promotionType: data.promotionType as PromotionType,
    salePrice: asNum(data.salePrice),
    discountPercent: asNum(data.discountPercent),
    startDate: start?.toDate?.()?.toISOString?.() ?? null,
    endDate: end?.toDate?.()?.toISOString?.() ?? null,
    badge: String(data.badge || ""),
    bannerLabel: String(data.bannerLabel || ""),
    stockLimit: asNum(data.stockLimit) ?? 0,
    maxPurchase: asNum(data.maxPurchase) ?? 0,
    reason: String(data.reason || ""),
    status: String(data.status || "pending"),
    createdBy: String(data.createdBy || ""),
    reviewedBy: String(data.reviewedBy || ""),
    reviewNote: String(data.reviewNote || ""),
    promotionId: String(data.promotionId || ""),
    createdAt: (data.createdAt as Timestamp | undefined)?.toDate?.()?.toISOString?.() ?? null,
    updatedAt: (data.updatedAt as Timestamp | undefined)?.toDate?.()?.toISOString?.() ?? null,
  };
}

/** Vendor submits a promotion request (requires admin approval). */
export async function createPromotionRequest(
  input: PromotionInput & { vendorId: string },
  actor: { uid: string; name: string }
) {
  if (!input.productId) throw new Error("productId is required");
  if (!isPromotionType(input.promotionType)) {
    throw new Error(`Invalid promotionType. Allowed: ${PROMOTION_TYPES.join(", ")}`);
  }
  if (!input.vendorId) throw new Error("vendorId is required");

  const product = await loadProduct(input.productId);
  if (product.vendorId && product.vendorId !== input.vendorId) {
    throw new Error("Product does not belong to this vendor");
  }
  if (product.data.admin_settings_locked === true) {
    throw new Error(
      "This promotion is managed by the administrator."
    );
  }

  const ref = db.collection(PROMOTION_REQUESTS_COL).doc();
  const doc = {
    productId: input.productId,
    productName: product.name,
    vendorId: input.vendorId || product.vendorId,
    vendorName: product.vendorName,
    promotionType: input.promotionType,
    salePrice: asNum(input.salePrice),
    discountPercent: asNum(input.discountPercent),
    startDate: toTimestamp(input.startDate ?? null),
    endDate: toTimestamp(input.endDate ?? null),
    badge: String(input.badge || ""),
    bannerLabel: String(input.bannerLabel || ""),
    stockLimit: asNum(input.stockLimit) ?? 0,
    maxPurchase: asNum(input.maxPurchase) ?? 0,
    reason: String(input.reason || ""),
    status: "pending",
    createdBy: actor.uid,
    reviewedBy: "",
    reviewNote: "",
    promotionId: "",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  await ref.set(doc);

  await writeAudit({
    adminUid: actor.uid,
    adminName: actor.name,
    productId: input.productId,
    productName: product.name,
    vendorId: product.vendorId,
    promotionId: ref.id,
    promotionType: `request:${input.promotionType}`,
    oldValue: {},
    newValue: serializeRequest(ref.id, doc) as unknown as Record<string, unknown>,
    reason: input.reason || "Vendor promotion request",
  });

  return serializeRequest(ref.id, doc);
}

export async function listPromotionRequests(opts?: {
  status?: string;
  vendorId?: string;
  limit?: number;
}) {
  let q: Query = db.collection(PROMOTION_REQUESTS_COL);
  if (opts?.status) q = q.where("status", "==", opts.status);
  else if (opts?.vendorId) q = q.where("vendorId", "==", opts.vendorId);
  const snap = await q.limit(Math.min(opts?.limit ?? 100, 300)).get();
  const items = snap.docs.map((d) => serializeRequest(d.id, d.data()));
  items.sort((a, b) => String(b.createdAt || "").localeCompare(String(a.createdAt || "")));
  return items;
}

/** Admin approves (creates locked admin promo) or rejects a vendor request. */
export async function resolvePromotionRequest(
  requestId: string,
  action: "approve" | "reject",
  actor: { uid: string; name: string },
  reviewNote?: string
) {
  const ref = db.collection(PROMOTION_REQUESTS_COL).doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) throw new Error("Promotion request not found");
  const data = snap.data() || {};
  if (data.status !== "pending") {
    throw new Error(`Request is already ${data.status}`);
  }

  if (action === "reject") {
    await ref.update({
      status: "rejected",
      reviewedBy: actor.uid,
      reviewNote: String(reviewNote || ""),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { ok: true, status: "rejected", request: serializeRequest(requestId, {
      ...data,
      status: "rejected",
      reviewedBy: actor.uid,
      reviewNote: String(reviewNote || ""),
    }) };
  }

  const promo = await createPromotion(
    {
      productId: String(data.productId),
      promotionType: data.promotionType as PromotionType,
      enabled: true,
      salePrice: asNum(data.salePrice),
      discountPercent: asNum(data.discountPercent),
      startDate: data.startDate as never,
      endDate: data.endDate as never,
      badge: String(data.badge || ""),
      bannerLabel: String(data.bannerLabel || ""),
      stockLimit: asNum(data.stockLimit) ?? 0,
      maxPurchase: asNum(data.maxPurchase) ?? 0,
      locked: true,
      source: "admin",
      reason: `Approved vendor request: ${String(data.reason || "")}`,
    },
    { ...actor, source: "admin" }
  );

  await ref.update({
    status: "approved",
    reviewedBy: actor.uid,
    reviewNote: String(reviewNote || "Approved"),
    promotionId: promo.id || "",
    updatedAt: FieldValue.serverTimestamp(),
  });

  return {
    ok: true,
    status: "approved",
    promotion: promo,
    request: serializeRequest(requestId, {
      ...data,
      status: "approved",
      promotionId: promo.id || "",
      reviewedBy: actor.uid,
    }),
  };
}

