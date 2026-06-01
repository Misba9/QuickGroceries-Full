import { logger } from "firebase-functions";
import { HttpsError, onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";
import * as admin from "firebase-admin";
import { expressOpenCors, REGION } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { createDeliveryAccountCore } from "./delivery_create_core";

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
        logger.error("delivery_http_error", e);
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
    res.status(401).json({
      success: false,
      error: "Missing Authorization Bearer token.",
    });
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

/** CORS-safe HTTP mirror for adminCreateDeliveryAccount (Flutter Web). */
export const adminCreateDeliveryAccountHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    await handlePost(req, res, async (body, adminUid) => {
      return createDeliveryAccountCore(
        {
          email: String(body.email ?? ""),
          password: String(body.password ?? ""),
          authUid: String(body.authUid ?? ""),
          firstName: String(body.firstName ?? ""),
          lastName: String(body.lastName ?? ""),
          phone: String(body.phone ?? ""),
          address: String(body.address ?? ""),
          image: String(body.image ?? ""),
          licenceNumber: String(body.licenceNumber ?? ""),
        },
        adminUid
      );
    });
  })
);

/** Alias requested by admin panel docs. */
export const createDeliveryBoy = adminCreateDeliveryAccountHttp;
