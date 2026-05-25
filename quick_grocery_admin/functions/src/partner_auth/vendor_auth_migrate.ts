import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError } from "firebase-functions/v2/https";
import { writeActivityLog } from "../operations/ops_notify";
import { hashPassword } from "./partner_crypto";
import { db } from "./partner_store";
import { buildSyncedVendorFields } from "./vendor_sync_fields";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function passwordRaw(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

async function updateVendorIdReferences(
  oldVendorId: string,
  newVendorId: string
): Promise<{ products: number; orders: number }> {
  let productsUpdated = 0;
  let ordersUpdated = 0;

  const productSnap = await db
    .collection("products")
    .where("vendor_id", "==", oldVendorId)
    .get();
  if (!productSnap.empty) {
    const batch = db.batch();
    productSnap.docs.forEach((doc) => {
      batch.update(doc.ref, { vendor_id: newVendorId });
    });
    await batch.commit();
    productsUpdated = productSnap.size;
  }

  const orderSnap = await db
    .collection("orders")
    .where("vendor_id", "==", oldVendorId)
    .get();
  if (!orderSnap.empty) {
    const batch = db.batch();
    orderSnap.docs.forEach((doc) => {
      batch.update(doc.ref, { vendor_id: newVendorId });
    });
    await batch.commit();
    ordersUpdated = orderSnap.size;
  }

  return { products: productsUpdated, orders: ordersUpdated };
}

async function resolveAuthUid(
  email: string,
  password: string,
  displayName: string
): Promise<{ uid: string; linked: boolean }> {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(existing.uid, { password, disabled: false });
    logger.info(`[vendorAuthMigrate] linked existing auth uid=${existing.uid} email=${email}`);
    return { uid: existing.uid, linked: true };
  } catch (e: unknown) {
    const err = e as { code?: string; message?: string };
    if (err.code !== "auth/user-not-found") {
      if (err.code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "Invalid vendor email address.");
      }
      throw new HttpsError(
        "failed-precondition",
        err.message ?? "Firebase Auth lookup failed."
      );
    }
  }

  try {
    const created = await admin.auth().createUser({
      email,
      password,
      displayName,
    });
    logger.info(`[vendorAuthMigrate] created auth uid=${created.uid} email=${email}`);
    return { uid: created.uid, linked: false };
  } catch (e: unknown) {
    const err = e as { code?: string; message?: string };
    if (err.code === "auth/email-already-exists") {
      const existing = await admin.auth().getUserByEmail(email);
      await admin.auth().updateUser(existing.uid, { password, disabled: false });
      return { uid: existing.uid, linked: true };
    }
    if (err.code === "auth/weak-password" || err.code === "auth/invalid-password") {
      throw new HttpsError("invalid-argument", "Password is too weak (min 8 characters).");
    }
    throw new HttpsError(
      "failed-precondition",
      err.message ?? "Could not create Firebase Authentication user."
    );
  }
}

export type MigrateVendorAuthResult = {
  success: boolean;
  authUid: string;
  previousDocId: string;
  firestorePath: string;
  linkedExistingAuth: boolean;
  referencesUpdated: { products: number; orders: number };
  temporaryPasswordNote?: string;
};

/**
 * Core migrate/restore: link or create Firebase Auth + sync Firestore vendor doc.
 */
export async function migrateVendorAuthCore(opts: {
  vendorDocId: string;
  password: string;
  adminUid?: string;
}): Promise<MigrateVendorAuthResult> {
  const vendorDocId = str(opts.vendorDocId);
  const password = passwordRaw(opts.password);

  logger.info(`[vendorAuthMigrate] start vendorDocId=${vendorDocId}`);

  if (!vendorDocId) {
    throw new HttpsError("invalid-argument", "vendorDocId is required.");
  }
  if (password.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Password must be at least 8 characters."
    );
  }

  const oldRef = db.collection("vendors").doc(vendorDocId);
  const oldSnap = await oldRef.get();
  if (!oldSnap.exists) {
    throw new HttpsError("not-found", "Vendor document not found.");
  }

  const data = oldSnap.data()!;
  const email = str(data.email).toLowerCase();
  if (!email.includes("@")) {
    throw new HttpsError("invalid-argument", "Vendor email is missing or invalid.");
  }

  const firstName = str(data.first_name || data.firstName);
  const lastName = str(data.last_name || data.lastName);
  const storeName =
    str(data.shop_name || data.shopName || data.storeName) || email;
  const displayName = `${firstName} ${lastName}`.trim() || storeName;

  const { uid, linked } = await resolveAuthUid(email, password, displayName);
  const passwordHash = await hashPassword(password);
  const ownerName =
    str(data.ownerName) || `${firstName} ${lastName}`.trim() || storeName;

  const vendorPayload = buildSyncedVendorFields({
    uid,
    email,
    ownerName,
    storeName,
    firstName: firstName || ownerName,
    lastName,
    passwordHash,
    existing: data as Record<string, unknown>,
  });

  if (vendorDocId !== uid) {
    vendorPayload.migratedFrom = vendorDocId;
  }

  let refs = { products: 0, orders: 0 };

  if (vendorDocId === uid) {
    await oldRef.set(vendorPayload, { merge: true });
    logger.info(`[vendorAuthMigrate] updated vendors/${uid} in place`);
  } else {
    const newRef = db.collection("vendors").doc(uid);
    const existingNew = await newRef.get();
    if (existingNew.exists && existingNew.id !== vendorDocId) {
      const existingData = existingNew.data() ?? {};
      const sameEmail =
        str(existingData.email).toLowerCase() === email;
      if (!sameEmail) {
        throw new HttpsError(
          "already-exists",
          `Firestore document vendors/${uid} already exists for another email.`
        );
      }
      await newRef.set(vendorPayload, { merge: true });
      logger.info(`[vendorAuthMigrate] merged into existing vendors/${uid}`);
    } else {
      await newRef.set(vendorPayload);
    }
    refs = await updateVendorIdReferences(vendorDocId, uid);
    await oldRef.delete();
    logger.info(
      `[vendorAuthMigrate] moved ${vendorDocId} → vendors/${uid} products=${refs.products} orders=${refs.orders}`
    );
  }

  await writeActivityLog({
    action: linked ? "restore_vendor_auth_link" : "restore_vendor_auth_create",
    entityType: "vendor",
    entityId: uid,
    summary: `${linked ? "Linked" : "Created"} Firebase Auth for ${storeName} (${email})`,
    metadata: {
      authUid: uid,
      previousDocId: vendorDocId,
      email,
      storeName,
      adminUid: opts.adminUid ?? "",
      ...refs,
    },
  });

  logger.info(`[vendorAuthMigrate] success uid=${uid} path=vendors/${uid}`);

  return {
    success: true,
    authUid: uid,
    previousDocId: vendorDocId,
    firestorePath: `vendors/${uid}`,
    linkedExistingAuth: linked,
    referencesUpdated: refs,
    temporaryPasswordNote:
      "Share the password you set with the vendor for first login.",
  };
}

/** Find vendor doc id by shop name (case-insensitive). */
export async function findVendorDocIdByShopName(
  shopName: string
): Promise<string | null> {
  const name = str(shopName);
  if (!name) return null;

  const snap = await db.collection("vendors").get();
  const lower = name.toLowerCase();
  for (const doc of snap.docs) {
    const d = doc.data();
    const shop =
      str(d.shop_name || d.shopName || d.storeName).toLowerCase();
    if (shop === lower) return doc.id;
  }
  return null;
}
