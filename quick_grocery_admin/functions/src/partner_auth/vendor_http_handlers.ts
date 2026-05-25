import { logger } from "firebase-functions";
import { HttpsError, onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";
import * as admin from "firebase-admin";
import { expressOpenCors, REGION } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { migrateVendorAuthCore } from "./vendor_auth_migrate";

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
        logger.error("vendor_http_error", e);
        const msg =
          e instanceof HttpsError
            ? e.message
            : e instanceof Error
              ? e.message
              : String(e);
        if (!res.headersSent) {
          res.status(500).json({ success: false, error: msg });
        }
      });
    });
  };
}

async function handlePost(
  req: Request,
  res: Response,
  run: (body: Record<string, unknown>, adminUid: string) => Promise<Record<string, unknown>>
) {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    res.status(405).json({ success: false, error: "POST required" });
    return;
  }

  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({ success: false, error: "Missing Authorization Bearer token." });
    return;
  }
  const token = authHeader.slice("Bearer ".length).trim();
  const decoded = await admin.auth().verifyIdToken(token);
  await assertNotificationAdmin(decoded.uid);

  const body = parseJsonBody(req);
  const result = await run(body, decoded.uid);
  if (!res.headersSent) {
    res.status(200).json({ ...result, ok: true });
  }
}

/** CORS-safe HTTP mirror for adminMigrateVendorAuth (Flutter Web). */
export const adminMigrateVendorAuthHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    await handlePost(req, res, async (body, adminUid) => {
      const vendorDocId = String(body.vendorDocId ?? "").trim();
      const password = String(body.password ?? "");
      const result = await migrateVendorAuthCore({
        vendorDocId,
        password,
        adminUid,
      });
      return result as unknown as Record<string, unknown>;
    });
  })
);

/** Restore by shopName or vendorDocId. */
export const adminRestoreVendorAuthHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    await handlePost(req, res, async (body, adminUid) => {
      const { findVendorDocIdByShopName, migrateVendorAuthCore: migrate } =
        await import("./vendor_auth_migrate");
      let vendorDocId = String(body.vendorDocId ?? "").trim();
      const shopName = String(body.shopName ?? "").trim();
      if (!vendorDocId && shopName) {
        const found = await findVendorDocIdByShopName(shopName);
        if (!found) {
          throw new HttpsError("not-found", `No vendor found for shop "${shopName}".`);
        }
        vendorDocId = found;
      }
      const password = String(body.password ?? "");
      return migrate({
        vendorDocId,
        password,
        adminUid,
      }) as unknown as Record<string, unknown>;
    });
  })
);
