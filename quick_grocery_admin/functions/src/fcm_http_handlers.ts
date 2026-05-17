import { logger } from "firebase-functions";
import { HttpsError, onRequest } from "firebase-functions/v2/https";
import type { Request, Response } from "express";
import { expressOpenCors, REGION } from "./https_callable_options";
import {
  assertHttpNotificationAdmin,
  runSendSingleNotification,
  runSendTopicNotification,
} from "./fcm_notification_exec";

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

function httpsErrorToMessage(e: unknown): string {
  if (e instanceof HttpsError) return e.message;
  if (e instanceof Error) return e.message;
  return String(e);
}

function sendJsonError(res: Response, status: number, error: string) {
  if (res.headersSent) return;
  res.status(status).json({ success: false, error });
}

/**
 * Wraps an HTTP handler with the `cors` package (`origin: true`) so Flutter Web
 * on localhost and hosted admin panels pass preflight + POST.
 */
function withCors(
  handler: (req: Request, res: Response) => Promise<void>
): (req: Request, res: Response) => void {
  return (req: Request, res: Response) => {
    expressOpenCors(req, res, () => {
      void handler(req, res).catch((e: unknown) => {
        logger.error("fcm_http_handler_error", e);
        sendJsonError(res, 500, httpsErrorToMessage(e));
      });
    });
  };
}

async function handlePost(
  req: Request,
  res: Response,
  run: (body: Record<string, unknown>) => Promise<Record<string, unknown>>
) {
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }
  if (req.method !== "POST") {
    sendJsonError(res, 405, "POST required");
    return;
  }

  await assertHttpNotificationAdmin(req.headers.authorization);
  const body = parseJsonBody(req);
  const result = await run(body);
  if (!res.headersSent) {
    res.status(200).json(result);
  }
}

/**
 * POST JSON body — same fields as [sendTopicNotification] callable.
 * Authorization: Bearer <Firebase ID token>
 */
export const sendTopicNotificationHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    await handlePost(req, res, async (body) => {
      const result = await runSendTopicNotification(body);
      return { ...result, ok: true };
    });
  })
);

/**
 * POST JSON body — same fields as [sendSingleNotification] callable.
 */
export const sendSingleNotificationHttp = onRequest(
  { region: REGION, cors: true },
  withCors(async (req, res) => {
    await handlePost(req, res, async (body) => {
      const result = await runSendSingleNotification(body);
      return { ...result, ok: true };
    });
  })
);
