import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import { writeActivityLog } from "../operations/ops_notify";
import { hashPassword } from "./partner_crypto";
import { db } from "./partner_store";
import { buildSyncedVendorFields } from "./vendor_sync_fields";
import {
  findVendorDocIdByShopName,
  migrateVendorAuthCore,
} from "./vendor_auth_migrate";

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
  { ...callableBaseOptions(), cors: true },
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

      await vendorRef.set(
        buildSyncedVendorFields({
          uid,
          email,
          ownerName,
          storeName,
          firstName,
          lastName,
          passwordHash,
          existing: {
            shop_address: shopAddress,
            vendor_image: vendorImage,
            shop_image: shopImage,
            createdAt: FieldValue.serverTimestamp(),
          },
        })
      );

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
        "failed-precondition",
        "Vendor profile could not be saved. Auth user was rolled back."
      );
    }
  }
);

/** Rollback Auth user when client-side creation succeeded but Firestore save failed. */
export const adminRollbackVendorAuth = onCall(
  { ...callableBaseOptions(), cors: true },
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
  { ...callableBaseOptions(), cors: true },
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

/**
 * Migrate legacy Firestore-only vendor → Firebase Auth + vendors/{auth.uid}.
 */
export const adminMigrateVendorAuth = onCall(
  { ...callableBaseOptions(), cors: true },
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const vendorDocId = str(req.data?.vendorDocId);
    const password = passwordRaw(req.data?.password);
    return migrateVendorAuthCore({
      vendorDocId,
      password,
      adminUid: req.auth?.uid,
    });
  }
);

/**
 * Restore vendor auth by doc id or shop name (e.g. "Honey Traders").
 */
export const adminRestoreVendorAuth = onCall(
  { ...callableBaseOptions(), cors: true },
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);

    let vendorDocId = str(req.data?.vendorDocId);
    const shopName = str(req.data?.shopName);
    const password = passwordRaw(req.data?.password);

    if (!vendorDocId && shopName) {
      const found = await findVendorDocIdByShopName(shopName);
      if (!found) {
        throw new HttpsError(
          "not-found",
          `No vendor found with shop name "${shopName}".`
        );
      }
      vendorDocId = found;
      logger.info(`[adminRestoreVendorAuth] resolved shopName=${shopName} → ${vendorDocId}`);
    }

    if (!vendorDocId) {
      throw new HttpsError(
        "invalid-argument",
        "vendorDocId or shopName is required."
      );
    }

    return migrateVendorAuthCore({
      vendorDocId,
      password,
      adminUid: req.auth?.uid,
    });
  }
);
