import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  createPromotion,
  createPromotionRequest,
  deletePromotion,
  getPromotion,
  listPromotionRequests,
  listPromotions,
  patchProductPromotions,
  resolvePromotionRequest,
  updatePromotion,
} from "./promotion_engine";
import { isPromotionType, type ProductPromotionPatch } from "./promotion_types";

async function actorFromAuth(uid: string): Promise<{ uid: string; name: string }> {
  const user = await admin.auth().getUser(uid);
  return {
    uid,
    name: user.displayName || user.email || uid,
  };
}

function asError(e: unknown): HttpsError {
  if (e instanceof HttpsError) return e;
  const msg = e instanceof Error ? e.message : String(e);
  if (/not found/i.test(msg)) return new HttpsError("not-found", msg);
  if (/required|invalid/i.test(msg)) return new HttpsError("invalid-argument", msg);
  return new HttpsError("internal", msg);
}

/** Admin: list promotions (optional productId / vendorId filters). */
export const adminListPromotionsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    try {
      const items = await listPromotions({
        productId: data.productId ? String(data.productId) : undefined,
        vendorId: data.vendorId ? String(data.vendorId) : undefined,
        enabledOnly: data.enabledOnly === true,
        includeExpired: data.includeExpired === true,
        limit: typeof data.limit === "number" ? data.limit : 500,
      });
      return { ok: true, promotions: items };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: create a promotion document. */
export const adminCreatePromotionCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const uid = request.auth!.uid;
    const actor = await actorFromAuth(uid);
    const data = (request.data || {}) as Record<string, unknown>;
    try {
      if (!data.productId || !data.promotionType) {
        throw new HttpsError("invalid-argument", "productId and promotionType required");
      }
      if (!isPromotionType(data.promotionType)) {
        throw new HttpsError("invalid-argument", "Invalid promotionType");
      }
      const promo = await createPromotion(
        {
          productId: String(data.productId),
          promotionType: data.promotionType,
          enabled: data.enabled !== false,
          salePrice: data.salePrice as number | null | undefined,
          discountPercent: data.discountPercent as number | null | undefined,
          startDate: data.startDate as never,
          endDate: data.endDate as never,
          badge: data.badge != null ? String(data.badge) : undefined,
          bannerLabel: data.bannerLabel != null ? String(data.bannerLabel) : undefined,
          priority: data.priority as number | undefined,
          maxPurchase: data.maxPurchase as number | undefined,
          stockLimit: data.stockLimit as number | undefined,
          pinToTop: data.pinToTop === true,
          visible: data.visible !== false,
          locked: data.locked !== false,
          source: "admin",
          reason: data.reason != null ? String(data.reason) : undefined,
        },
        actor
      );
      return { ok: true, promotion: promo };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: update promotion by id. */
export const adminUpdatePromotionCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const actor = await actorFromAuth(request.auth!.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const id = String(data.id || data.promotionId || "");
    if (!id) throw new HttpsError("invalid-argument", "id is required");
    try {
      const promo = await updatePromotion(id, { ...data, _allowLocked: true }, actor);
      return { ok: true, promotion: promo };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: delete promotion by id. */
export const adminDeletePromotionCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const actor = await actorFromAuth(request.auth!.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const id = String(data.id || data.promotionId || "");
    if (!id) throw new HttpsError("invalid-argument", "id is required");
    try {
      const result = await deletePromotion(id, {
        ...actor,
        reason: data.reason != null ? String(data.reason) : "deleted",
      });
      return result;
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Public read: list active promotions for product(s). */
export const listProductPromotionsCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (request) => {
    const data = (request.data || {}) as Record<string, unknown>;
    try {
      const items = await listPromotions({
        productId: data.productId ? String(data.productId) : undefined,
        enabledOnly: true,
        includeExpired: false,
        limit: typeof data.limit === "number" ? data.limit : 200,
      });
      return { ok: true, promotions: items };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: bulk patch promotion flags/pricing for one product. */
export const patchProductPromotionsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const actor = await actorFromAuth(request.auth!.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const productId = String(data.productId || data.id || "");
    if (!productId) throw new HttpsError("invalid-argument", "productId required");
    try {
      const patch = data as ProductPromotionPatch & { productId?: string };
      const result = await patchProductPromotions(productId, patch, actor);
      return result;
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Get a single promotion. */
export const getPromotionCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const id = String((request.data as { id?: string })?.id || "");
    if (!id) throw new HttpsError("invalid-argument", "id required");
    const promo = await getPromotion(id);
    if (!promo) throw new HttpsError("not-found", "Promotion not found");
    return { ok: true, promotion: promo };
  }
);

/** Vendor: request a promotion for their product (pending admin approval). */
export const vendorRequestPromotionCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const actor = await actorFromAuth(request.auth.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const productId = String(data.productId || "");
    const vendorId = String(data.vendorId || request.auth.uid);
    const promotionType = data.promotionType;
    if (!productId || !isPromotionType(promotionType)) {
      throw new HttpsError(
        "invalid-argument",
        "productId and valid promotionType required",
      );
    }
    try {
      const reqDoc = await createPromotionRequest(
        {
          productId,
          vendorId,
          promotionType,
          salePrice: data.salePrice as number | null | undefined,
          discountPercent: data.discountPercent as number | null | undefined,
          startDate: data.startDate as never,
          endDate: data.endDate as never,
          badge: data.badge != null ? String(data.badge) : undefined,
          bannerLabel:
            data.bannerLabel != null ? String(data.bannerLabel) : undefined,
          stockLimit: data.stockLimit as number | undefined,
          maxPurchase: data.maxPurchase as number | undefined,
          reason: data.reason != null ? String(data.reason) : undefined,
        },
        actor
      );
      return { ok: true, request: reqDoc };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: list vendor promotion requests. */
export const adminListPromotionRequestsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    try {
      const items = await listPromotionRequests({
        status: data.status ? String(data.status) : "pending",
        vendorId: data.vendorId ? String(data.vendorId) : undefined,
        limit: typeof data.limit === "number" ? data.limit : 100,
      });
      return { ok: true, requests: items };
    } catch (e) {
      throw asError(e);
    }
  }
);

/** Admin: approve or reject a vendor promotion request. */
export const adminResolvePromotionRequestCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const actor = await actorFromAuth(request.auth!.uid);
    const data = (request.data || {}) as Record<string, unknown>;
    const id = String(data.id || data.requestId || "");
    const action = String(data.action || "").toLowerCase();
    if (!id || (action !== "approve" && action !== "reject")) {
      throw new HttpsError(
        "invalid-argument",
        "id and action (approve|reject) required",
      );
    }
    try {
      const result = await resolvePromotionRequest(
        id,
        action as "approve" | "reject",
        actor,
        data.reviewNote != null ? String(data.reviewNote) : undefined
      );
      return result;
    } catch (e) {
      throw asError(e);
    }
  }
);
