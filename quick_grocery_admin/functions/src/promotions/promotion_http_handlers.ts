import { logger } from "firebase-functions";
import { HttpsError, onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";
import * as admin from "firebase-admin";
import { expressOpenCors, REGION } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  createPromotion,
  deletePromotion,
  getPromotion,
  listPromotions,
  patchProductPromotions,
  updatePromotion,
} from "./promotion_engine";
import { isPromotionType, type ProductPromotionPatch } from "./promotion_types";

function parseJsonBody(req: Request): Record<string, unknown> {
  const raw = req.body;
  if (raw == null) return {};
  if (typeof raw === "object" && !Array.isArray(raw)) {
    return raw as Record<string, unknown>;
  }
  if (typeof raw === "string" && raw.trim()) {
    return JSON.parse(raw) as Record<string, unknown>;
  }
  return {};
}

function withCors(
  handler: (req: Request, res: Response) => Promise<void>
): (req: Request, res: Response) => void {
  return (req: Request, res: Response) => {
    expressOpenCors(req, res, () => {
      void handler(req, res).catch((e: unknown) => {
        logger.error("product_promotions_http_error", e);
        const msg =
          e instanceof HttpsError
            ? e.message
            : e instanceof Error
              ? e.message
              : String(e);
        const status =
          e instanceof HttpsError
            ? e.httpErrorCode?.status || 500
            : /unauth|sign in|Bearer/i.test(msg)
              ? 401
              : /permission|admin/i.test(msg)
                ? 403
                : 500;
        if (!res.headersSent) {
          res.status(status).json({ ok: false, error: msg });
        }
      });
    });
  };
}

async function requireAdmin(req: Request): Promise<{ uid: string; name: string }> {
  const header = req.headers.authorization || "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) {
    throw new HttpsError("unauthenticated", "Missing Authorization Bearer token");
  }
  const decoded = await admin.auth().verifyIdToken(match[1]);
  await assertNotificationAdmin(decoded.uid);
  const user = await admin.auth().getUser(decoded.uid);
  return { uid: decoded.uid, name: user.displayName || user.email || decoded.uid };
}

/**
 * REST-style admin promotions API:
 *   GET    /admin/promotions
 *   POST   /admin/promotions
 *   PUT    /admin/promotions/:id
 *   DELETE /admin/promotions/:id
 *   GET    /products/promotions
 *   PATCH  /products/:id/promotions
 */
export const productPromotionsHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    const rawPath = (req.path || req.url || "").split("?")[0];
    const path =
      rawPath.replace(/^\/productPromotionsHttp/, "").replace(/\/+$/, "") || "/";

    if (req.method === "GET" && path === "/products/promotions") {
      const productId = String(req.query.productId || "");
      const items = await listPromotions({
        productId: productId || undefined,
        enabledOnly: true,
        includeExpired: false,
      });
      res.status(200).json({ ok: true, promotions: items });
      return;
    }

    const patchMatch = /^\/products\/([^/]+)\/promotions$/.exec(path);
    if (req.method === "PATCH" && patchMatch) {
      const actor = await requireAdmin(req);
      const productId = decodeURIComponent(patchMatch[1]);
      const body = parseJsonBody(req) as ProductPromotionPatch;
      const result = await patchProductPromotions(productId, body, actor);
      res.status(200).json(result);
      return;
    }

    if (path === "/admin/promotions" || path.startsWith("/admin/promotions/")) {
      const actor = await requireAdmin(req);
      const idMatch = /^\/admin\/promotions\/([^/]+)$/.exec(path);
      const id = idMatch ? decodeURIComponent(idMatch[1]) : null;

      if (req.method === "GET" && !id) {
        const items = await listPromotions({
          productId: req.query.productId ? String(req.query.productId) : undefined,
          vendorId: req.query.vendorId ? String(req.query.vendorId) : undefined,
          enabledOnly: req.query.enabledOnly === "true",
          includeExpired: req.query.includeExpired === "true",
        });
        res.status(200).json({ ok: true, promotions: items });
        return;
      }

      if (req.method === "GET" && id) {
        const promo = await getPromotion(id);
        if (!promo) {
          res.status(404).json({ ok: false, error: "Not found" });
          return;
        }
        res.status(200).json({ ok: true, promotion: promo });
        return;
      }

      if (req.method === "POST" && !id) {
        const body = parseJsonBody(req);
        if (!body.productId || !isPromotionType(body.promotionType)) {
          res.status(400).json({
            ok: false,
            error: "productId and valid promotionType required",
          });
          return;
        }
        const promo = await createPromotion(
          {
            productId: String(body.productId),
            promotionType: body.promotionType,
            enabled: body.enabled !== false,
            salePrice: body.salePrice as number | null | undefined,
            discountPercent: body.discountPercent as number | null | undefined,
            startDate: body.startDate as never,
            endDate: body.endDate as never,
            badge: body.badge != null ? String(body.badge) : undefined,
            bannerLabel:
              body.bannerLabel != null ? String(body.bannerLabel) : undefined,
            priority: body.priority as number | undefined,
            maxPurchase: body.maxPurchase as number | undefined,
            stockLimit: body.stockLimit as number | undefined,
            pinToTop: body.pinToTop === true,
            visible: body.visible !== false,
            locked: body.locked !== false,
            source: "admin",
            reason: body.reason != null ? String(body.reason) : undefined,
          },
          actor
        );
        res.status(201).json({ ok: true, promotion: promo });
        return;
      }

      if (req.method === "PUT" && id) {
        const body = parseJsonBody(req);
        const promo = await updatePromotion(id, { ...body, _allowLocked: true }, actor);
        res.status(200).json({ ok: true, promotion: promo });
        return;
      }

      if (req.method === "DELETE" && id) {
        const body = parseJsonBody(req);
        const result = await deletePromotion(id, {
          ...actor,
          reason: body.reason != null ? String(body.reason) : "deleted",
        });
        res.status(200).json(result);
        return;
      }
    }

    res.status(404).json({ ok: false, error: `No route for ${req.method} ${path}` });
  })
);
