import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  createDeliveryAccountCore,
  rollbackAuthUser,
} from "./delivery_create_core";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function passwordRaw(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

/** Admin creates Firebase Auth user + Firestore `delivery_boys/{auth.uid}`. */
export const adminCreateDeliveryAccount = onCall(
  { ...callableBaseOptions(), cors: true },
  async (req) => {
    const adminUid = req.auth?.uid;
    await assertNotificationAdmin(adminUid);

    return createDeliveryAccountCore(
      {
        email: str(req.data?.email),
        password: passwordRaw(req.data?.password),
        authUid: str(req.data?.authUid),
        firstName: str(req.data?.firstName),
        lastName: str(req.data?.lastName),
        phone: str(req.data?.phone),
        address: str(req.data?.address),
        image: str(req.data?.image),
        licenceNumber: str(req.data?.licenceNumber),
      },
      adminUid ?? "unknown"
    );
  }
);

/** Rollback Auth user when client-side creation succeeded but Firestore save failed. */
export const adminRollbackDeliveryAuth = onCall(
  { ...callableBaseOptions(), cors: true },
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const uid = str(req.data?.authUid);
    if (!uid) {
      throw new HttpsError("invalid-argument", "authUid is required.");
    }
    await rollbackAuthUser(uid);
    logger.info(`[adminRollbackDeliveryAuth] deleted auth uid=${uid}`);
    return { success: true };
  }
);
