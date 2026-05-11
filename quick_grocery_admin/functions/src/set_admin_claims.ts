import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { hasElevatedAdmin } from "./roles";

const REGION = "us-central1";

const MIN_BOOTSTRAP_LEN = 12;

/**
 * Sets `admin`, `smsAdmin`, and `role: "admin"` (merged over existing claims).
 *
 * - **Bootstrap**: `bootstrapSecret` === env `ADMIN_BOOTSTRAP_SECRET` (length ≥ 12) →
 *   elevates **only** the signed-in user.
 * - **Admin promote**: existing elevated admin may pass `uid` to grant another account.
 */
export const setAdminClaims = onCall({ region: REGION }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }

  const targetUidRaw =
    request.data?.uid != null ? String(request.data.uid).trim() : "";
  const bootstrapSecret =
    request.data?.bootstrapSecret != null
      ? String(request.data.bootstrapSecret)
      : "";

  const caller = await admin.auth().getUser(callerUid);
  const callerClaims = (caller.customClaims || {}) as Record<string, unknown>;

  const envSecret = (process.env.ADMIN_BOOTSTRAP_SECRET || "").trim();
  const secretOk =
    envSecret.length >= MIN_BOOTSTRAP_LEN && bootstrapSecret === envSecret;

  let targetUid: string;
  if (secretOk) {
    targetUid = callerUid;
    if (targetUidRaw.length > 0 && targetUidRaw !== callerUid) {
      throw new HttpsError(
        "permission-denied",
        "Bootstrap secret may only elevate the signed-in account."
      );
    }
  } else if (targetUidRaw.length > 0) {
    targetUid = targetUidRaw;
    if (targetUid !== callerUid && !hasElevatedAdmin(callerClaims)) {
      throw new HttpsError(
        "permission-denied",
        "Only an existing admin can set claims for another user."
      );
    }
  } else {
    targetUid = callerUid;
    if (!hasElevatedAdmin(callerClaims)) {
      throw new HttpsError(
        "permission-denied",
        "Configure ADMIN_BOOTSTRAP_SECRET on the function (12+ chars) and pass it once, or ask an admin to grant your account."
      );
    }
  }

  const target = await admin.auth().getUser(targetUid);
  const prev = (target.customClaims || {}) as Record<string, unknown>;
  const next: Record<string, unknown> = {
    ...prev,
    admin: true,
    smsAdmin: true,
    notificationsAdmin: true,
    superAdmin: true,
    role: "superAdmin",
  };

  await admin.auth().setCustomUserClaims(targetUid, next);
  logger.info("setAdminClaims", {
    targetUid,
    callerUid,
    viaBootstrap: secretOk,
  });

  return {
    ok: true,
    uid: targetUid,
    claims: next,
  };
});
