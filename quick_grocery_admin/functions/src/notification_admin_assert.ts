import * as admin from "firebase-admin";
import { HttpsError } from "firebase-functions/v2/https";
import { isBootstrapPanelEmail } from "./bootstrap_emails";
import { hasSmsPanelAccess } from "./roles";

const db = admin.firestore();

function emailVariantsForAdmins(email: string): string[] {
  const t = email.trim();
  const l = t.toLowerCase();
  return [...new Set([email, t, l])];
}

export async function userEmailInAdminsTable(
  email: string | undefined
): Promise<boolean> {
  if (!email) return false;
  for (const v of emailVariantsForAdmins(email)) {
    const snap = await db
      .collection("admins")
      .where("email", "==", v)
      .limit(1)
      .get();
    if (!snap.empty) return true;
  }
  return false;
}

export async function assertNotificationAdmin(
  uid: string | undefined
): Promise<void> {
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const user = await admin.auth().getUser(uid);
  const c = (user.customClaims || {}) as Record<string, unknown>;
  if (hasSmsPanelAccess(c)) return;
  if (await userEmailInAdminsTable(user.email)) return;
  if (isBootstrapPanelEmail(user.email)) return;
  throw new HttpsError(
    "permission-denied",
    "Push notifications require admin claims, an `admins` row, or bootstrap email match."
  );
}
