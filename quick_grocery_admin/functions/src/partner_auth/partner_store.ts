import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

const db = admin.firestore();

export type PartnerRole = "vendor" | "delivery";

export const OTP_EXPIRY_MS = 5 * 60 * 1000;
export const RESEND_COOLDOWN_MS = 30 * 1000;
export const MAX_OTP_ATTEMPTS = 3;
export const MAX_LOGIN_ATTEMPTS = 5;
export const LOCK_DURATION_MS = 30 * 60 * 1000;
export const RESET_VERIFIED_MS = 15 * 60 * 1000;

export function collectionForRole(role: PartnerRole): string {
  return role === "vendor" ? "vendors" : "delivery_boys";
}

export function appNameForRole(role: PartnerRole): string {
  return role === "vendor" ? "Quick Groceries Vendor" : "Quick Groceries Delivery";
}

export async function findPartnerByEmail(
  role: PartnerRole,
  email: string
): Promise<{ id: string; data: admin.firestore.DocumentData } | null> {
  const normalized = email.trim().toLowerCase();
  const snap = await db
    .collection(collectionForRole(role))
    .where("email", "==", normalized)
    .limit(1)
    .get();
  if (snap.empty) {
    const snapRaw = await db
      .collection(collectionForRole(role))
      .where("email", "==", email.trim())
      .limit(1)
      .get();
    if (snapRaw.empty) return null;
    const doc = snapRaw.docs[0];
    return { id: doc.id, data: doc.data() };
  }
  const doc = snap.docs[0];
  return { id: doc.id, data: doc.data() };
}

export function isAccountActive(data: admin.firestore.DocumentData): boolean {
  return data.is_active !== false;
}

export function isLocked(data: admin.firestore.DocumentData): boolean {
  const until = data.locked_until as Timestamp | undefined;
  if (!until) return false;
  return until.toMillis() > Date.now();
}

export async function getPartnerDoc(
  role: PartnerRole,
  partnerId: string
): Promise<FirebaseFirestore.DocumentSnapshot> {
  return db.collection(collectionForRole(role)).doc(partnerId).get();
}

export { db, FieldValue, Timestamp };
