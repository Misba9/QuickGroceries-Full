import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { isBootstrapPanelEmail } from "./bootstrap_emails";

const REGION = "us-central1";

function emailVariants(email: string): string[] {
  const t = email.trim();
  const l = t.toLowerCase();
  return [...new Set([email, t, l])];
}

/**
 * If the signed-in user's email exists in Firestore `admins`, sets full
 * notification + SMS custom claims (same bundle as manual promotion).
 */
export const syncAdminClaimsFromAdmins = onCall({ region: REGION }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const db = admin.firestore();
  const user = await admin.auth().getUser(uid);
  const emailRaw = user.email;
  if (!emailRaw) {
    throw new HttpsError(
      "failed-precondition",
      "This Firebase user has no email; cannot match admins collection."
    );
  }
  let matched = false;
  for (const v of emailVariants(emailRaw)) {
    const snap = await db.collection("admins").where("email", "==", v).limit(1).get();
    if (!snap.empty) {
      matched = true;
      break;
    }
  }
  if (!matched && !isBootstrapPanelEmail(emailRaw)) {
    throw new HttpsError(
      "permission-denied",
      "No document in `admins` matches this account email, and it is not on BOOTSTRAP_ADMIN_EMAILS."
    );
  }
  if (!matched && isBootstrapPanelEmail(emailRaw)) {
    logger.info("syncAdminClaimsFromAdmins bootstrap email (no admins doc)", {
      uid,
      email: emailRaw,
    });
  }
  const prev = (user.customClaims || {}) as Record<string, unknown>;
  const next: Record<string, unknown> = {
    ...prev,
    admin: true,
    smsAdmin: true,
    notificationsAdmin: true,
    superAdmin: true,
    role: "superAdmin",
  };
  await admin.auth().setCustomUserClaims(uid, next);
  logger.info("syncAdminClaimsFromAdmins", { uid, email: emailRaw });
  return { ok: true, claims: next };
});
