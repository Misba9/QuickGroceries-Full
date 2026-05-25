import { FieldValue } from "firebase-admin/firestore";

/** Normalized vendor fields after Firebase Auth sync (admin + vendor app). */
export function buildSyncedVendorFields(opts: {
  uid: string;
  email: string;
  ownerName: string;
  storeName: string;
  firstName: string;
  lastName: string;
  passwordHash: string;
  existing?: Record<string, unknown>;
}): Record<string, unknown> {
  const base = opts.existing ?? {};
  return {
    ...base,
    id: opts.uid,
    uid: opts.uid,
    auth_uid: opts.uid,
    authUid: opts.uid,
    email: opts.email,
    ownerName: opts.ownerName,
    storeName: opts.storeName,
    shopName: opts.storeName,
    first_name: opts.firstName || opts.ownerName,
    last_name: opts.lastName,
    shop_name: opts.storeName,
    status: "approved",
    isApproved: true,
    isBlocked: false,
    is_active: true,
    isActive: true,
    authSynced: true,
    firebaseAuth: true,
    syncStatus: "synced",
    password_hash: opts.passwordHash,
    updatedAt: FieldValue.serverTimestamp(),
    syncedAt: FieldValue.serverTimestamp(),
  };
}
