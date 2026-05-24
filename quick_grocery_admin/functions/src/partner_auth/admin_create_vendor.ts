import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { writeActivityLog } from "../operations/ops_notify";
import { hashPassword } from "./partner_crypto";
import { db } from "./partner_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

/** Password must not be trimmed — must match vendor login input exactly. */
function passwordRaw(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

async function rollbackAuthUser(uid: string): Promise<void> {
  await admin.auth().deleteUser(uid).catch(() => undefined);
}

/** Admin creates Firebase Auth user + Firestore `vendors/{auth.uid}`. */
export const adminCreateVendorAccount = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);

    const email = str(req.data?.email).toLowerCase();
    const password = passwordRaw(req.data?.password);
    const preCreatedAuthUid = str(req.data?.authUid);
    const firstName = str(req.data?.firstName);
    const lastName = str(req.data?.lastName);
    const storeName = str(req.data?.storeName);
    const phone = str(req.data?.phone);
    const shopAddress = str(req.data?.shopAddress);
    const vendorImage = str(req.data?.vendorImage);
    const shopImage = str(req.data?.shopImage);

    logger.info(`[adminCreateVendorAccount] email=${email} authUid=${preCreatedAuthUid || "(create)"}`);

    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email is required.");
    }
    if (password.length < 8) {
      throw new HttpsError(
        "invalid-argument",
        "Password must be at least 8 characters."
      );
    }
    if (!firstName) {
      throw new HttpsError("invalid-argument", "First name is required.");
    }
    if (!lastName) {
      throw new HttpsError("invalid-argument", "Last name is required.");
    }
    if (!storeName) {
      throw new HttpsError("invalid-argument", "Store name is required.");
    }
    if (phone.length < 10) {
      throw new HttpsError("invalid-argument", "Valid phone number is required.");
    }
    if (!shopAddress) {
      throw new HttpsError("invalid-argument", "Shop address is required.");
    }

    const existingSnap = await db
      .collection("vendors")
      .where("email", "==", email)
      .limit(1)
      .get();
    if (!existingSnap.empty) {
      const existingId = existingSnap.docs[0].id;
      throw new HttpsError(
        "already-exists",
        `A vendor with this email already exists (vendors/${existingId}). ` +
          "Use Sync Firebase Auth on Vendor List instead of creating a duplicate."
      );
    }

    let uid = preCreatedAuthUid;

    if (uid) {
      try {
        const userRecord = await admin.auth().getUser(uid);
        const authEmail = (userRecord.email ?? "").toLowerCase();
        if (authEmail !== email) {
          throw new HttpsError(
            "invalid-argument",
            "Auth UID does not match the provided email."
          );
        }
        logger.info(`[adminCreateVendorAccount] using pre-created auth uid=${uid}`);
      } catch (e: unknown) {
        const err = e as { code?: string; message?: string };
        if (err.code === "auth/user-not-found") {
          throw new HttpsError(
            "not-found",
            "Firebase Authentication user not found for authUid."
          );
        }
        throw e;
      }
    } else {
      let userRecord: admin.auth.UserRecord;
      try {
        userRecord = await admin.auth().createUser({
          email,
          password,
          displayName: `${firstName} ${lastName}`.trim() || storeName,
        });
      } catch (e: unknown) {
        const err = e as { code?: string; message?: string };
        logger.warn("[adminCreateVendorAccount] auth create failed", err);
        if (err.code === "auth/email-already-exists") {
          throw new HttpsError(
            "already-exists",
            "Firebase Authentication account already exists for this email."
          );
        }
        if (err.code === "auth/invalid-password") {
          throw new HttpsError("invalid-argument", "Password is too weak.");
        }
        if (err.code === "auth/invalid-email") {
          throw new HttpsError("invalid-argument", "Invalid email address.");
        }
        throw new HttpsError(
          "internal",
          err.message ?? "Could not create Firebase Authentication user."
        );
      }
      uid = userRecord.uid;
    }

    const ownerName = `${firstName} ${lastName}`.trim();
    logger.info(`[adminCreateVendorAccount] auth uid=${uid} email=${email}`);

    try {
      const existingDoc = await db.collection("vendors").doc(uid).get();
      if (existingDoc.exists) {
        throw new HttpsError(
          "already-exists",
          `Firestore document vendors/${uid} already exists.`
        );
      }

      const passwordHash = await hashPassword(password);
      const vendorRef = db.collection("vendors").doc(uid);

      await vendorRef.set({
        id: uid,
        auth_uid: uid,
        email,
        ownerName,
        storeName,
        phone,
        status: "active",
        isApproved: true,
        isBlocked: false,
        createdAt: FieldValue.serverTimestamp(),
        first_name: firstName,
        last_name: lastName,
        shop_name: storeName,
        shop_address: shopAddress,
        vendor_image: vendorImage,
        shop_image: shopImage,
        is_active: true,
        password_hash: passwordHash,
      });

      const saved = await vendorRef.get();
      logger.info(
        `[adminCreateVendorAccount] firestore path=vendors/${uid} exists=${saved.exists}`
      );

      await writeActivityLog({
        action: "admin_create_vendor",
        entityType: "vendor",
        entityId: uid,
        summary: `Admin created vendor ${email} (${storeName})`,
        metadata: { email, storeName, authUid: uid },
      });

      return {
        success: true,
        authUid: uid,
        vendorId: uid,
        firestorePath: `vendors/${uid}`,
      };
    } catch (e) {
      logger.error("[adminCreateVendorAccount] firestore write failed", e);
      if (!preCreatedAuthUid) {
        await rollbackAuthUser(uid);
      }
      if (e instanceof HttpsError) throw e;
      throw new HttpsError(
        "internal",
        "Vendor profile could not be saved. Auth user was rolled back."
      );
    }
  }
);

/** Rollback Auth user when client-side creation succeeded but Firestore save failed. */
export const adminRollbackVendorAuth = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const uid = str(req.data?.authUid);
    if (!uid) {
      throw new HttpsError("invalid-argument", "authUid is required.");
    }
    await rollbackAuthUser(uid);
    logger.info(`[adminRollbackVendorAuth] deleted auth uid=${uid}`);
    return { success: true };
  }
);

/** Sync Firebase Auth password for an existing vendor (admin repair). */
export const adminSyncVendorAuthPassword = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const email = str(req.data?.email).toLowerCase();
    const password = passwordRaw(req.data?.password);
  if (!email || password.length < 8) {
      throw new HttpsError("invalid-argument", "Email and password (8+) required.");
    }

    let user: admin.auth.UserRecord;
    try {
      user = await admin.auth().getUserByEmail(email);
    } catch {
      throw new HttpsError(
        "not-found",
        "No Firebase Authentication user for this email."
      );
    }

    await admin.auth().updateUser(user.uid, { password });
    const passwordHash = await hashPassword(password);
    const ref = db.collection("vendors").doc(user.uid);
    const snap = await ref.get();
    if (snap.exists) {
      await ref.update({ password_hash: passwordHash, email });
    }

    logger.info(`[adminSyncVendorAuthPassword] updated uid=${user.uid} email=${email}`);
    return { success: true, authUid: user.uid };
  }
);

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

/**
 * Migrate legacy Firestore-only vendor → Firebase Auth + vendors/{auth.uid}.
 * Moves doc when Firestore ID ≠ Auth UID and updates product/order references.
 */
export const adminMigrateVendorAuth = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);

    const vendorDocId = str(req.data?.vendorDocId);
    const password = passwordRaw(req.data?.password);

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

    let uid: string;
    try {
      const existing = await admin.auth().getUserByEmail(email);
      uid = existing.uid;
      await admin.auth().updateUser(uid, { password, disabled: false });
      logger.info(`[adminMigrateVendorAuth] linked existing auth uid=${uid}`);
    } catch (e: unknown) {
      const err = e as { code?: string; message?: string };
      if (err.code !== "auth/user-not-found") {
        throw new HttpsError("internal", err.message ?? "Auth lookup failed.");
      }
      const created = await admin.auth().createUser({
        email,
        password,
        displayName,
      });
      uid = created.uid;
      logger.info(`[adminMigrateVendorAuth] created auth uid=${uid}`);
    }

    const passwordHash = await hashPassword(password);
    const ownerName =
      str(data.ownerName) || `${firstName} ${lastName}`.trim() || storeName;

    const vendorPayload: Record<string, unknown> = {
      ...data,
      id: uid,
      auth_uid: uid,
      email,
      ownerName,
      storeName,
      first_name: firstName || ownerName,
      last_name: lastName,
      shop_name: storeName,
      status: "active",
      isApproved: true,
      isBlocked: false,
      is_active: data.is_active !== false,
      password_hash: passwordHash,
      authSynced: true,
      migratedAt: FieldValue.serverTimestamp(),
    };

    if (vendorDocId !== uid) {
      vendorPayload.migratedFrom = vendorDocId;
    }

    let refs = { products: 0, orders: 0 };

    if (vendorDocId === uid) {
      await oldRef.set(vendorPayload, { merge: true });
      logger.info(`[adminMigrateVendorAuth] updated vendors/${uid} in place`);
    } else {
      const newRef = db.collection("vendors").doc(uid);
      const existingNew = await newRef.get();
      if (existingNew.exists && existingNew.id !== vendorDocId) {
        throw new HttpsError(
          "already-exists",
          `Firestore document vendors/${uid} already exists. Resolve conflict manually.`
        );
      }

      await newRef.set(vendorPayload);
      refs = await updateVendorIdReferences(vendorDocId, uid);
      await oldRef.delete();
      logger.info(
        `[adminMigrateVendorAuth] moved ${vendorDocId} → vendors/${uid} products=${refs.products} orders=${refs.orders}`
      );
    }

    await writeActivityLog({
      action: "migrate_vendor_auth",
      entityType: "vendor",
      entityId: uid,
      summary: `Migrated vendor ${email} to Firebase Auth`,
      metadata: {
        authUid:  uid,
        previousDocId: vendorDocId,
        email,
        ...refs,
      },
    });

    return {
      success: true,
      authUid: uid,
      previousDocId: vendorDocId,
      firestorePath: `vendors/${uid}`,
      referencesUpdated: refs,
    };
  }
);
