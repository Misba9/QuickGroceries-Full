import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { randomUUID } from "crypto";
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

function passwordRaw(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

async function createApprovedVendorProfile(opts: {
  uid: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  storeName: string;
  phone: string;
  shopAddress: string;
  vendorImage: string;
  shopImage: string;
}): Promise<void> {
  const ownerName = `${opts.firstName} ${opts.lastName}`.trim();
  const passwordHash = await hashPassword(opts.password);

  await db.collection("vendors").doc(opts.uid).set({
    id: opts.uid,
    auth_uid: opts.uid,
    email: opts.email,
    ownerName,
    storeName: opts.storeName,
    phone: opts.phone,
    status: "active",
    isApproved: true,
    isBlocked: false,
    createdAt: FieldValue.serverTimestamp(),
    first_name: opts.firstName,
    last_name: opts.lastName,
    shop_name: opts.storeName,
    shop_address: opts.shopAddress,
    vendor_image: opts.vendorImage,
    shop_image: opts.shopImage,
    is_active: true,
    password_hash: passwordHash,
    authSynced: true,
  });
}

const MAX_SIGNUP_IMAGE_BYTES = 5 * 1024 * 1024;

function storageDownloadUrl(bucketName: string, objectPath: string, token: string): string {
  const encoded = encodeURIComponent(objectPath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encoded}?alt=media&token=${token}`;
}

/** Public — upload signup image without Firebase Auth (Admin SDK → Storage). */
export const uploadVendorSignupImage = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const folder = str(req.data?.folder);
    const contentType = str(req.data?.contentType) || "image/jpeg";
    const imageBase64 = passwordRaw(req.data?.imageBase64);

    if (folder !== "vendor" && folder !== "shop") {
      throw new HttpsError("invalid-argument", "folder must be vendor or shop.");
    }
    if (!imageBase64) {
      throw new HttpsError("invalid-argument", "imageBase64 is required.");
    }

    let buffer: Buffer;
    try {
      buffer = Buffer.from(imageBase64, "base64");
    } catch {
      throw new HttpsError("invalid-argument", "Invalid image data.");
    }

    if (buffer.length > MAX_SIGNUP_IMAGE_BYTES) {
      throw new HttpsError("invalid-argument", "Image must be under 5MB.");
    }
    if (buffer.length < 64) {
      throw new HttpsError("invalid-argument", "Image data is too small.");
    }

    const ext = contentType.includes("png")
      ? "png"
      : contentType.includes("webp")
        ? "webp"
        : "jpg";
    const objectPath = `vendor_signup/${folder}/${Date.now()}_${randomUUID().slice(0, 8)}.${ext}`;
    const token = randomUUID();
    const bucket = admin.storage().bucket();

    await bucket.file(objectPath).save(buffer, {
      metadata: {
        contentType,
        metadata: { firebaseStorageDownloadTokens: token },
      },
    });

    const url = storageDownloadUrl(bucket.name, objectPath, token);
    logger.info(`[uploadVendorSignupImage] folder=${folder} path=${objectPath}`);
    return { success: true, url };
  }
);

/** Public — vendor app submits signup (no Firebase Auth yet). */
export const submitVendorRequest = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const firstName = str(req.data?.firstName);
    const lastName = str(req.data?.lastName);
    const phone = str(req.data?.phone);
    const email = str(req.data?.email).toLowerCase();
    const password = passwordRaw(req.data?.password);
    const shopName = str(req.data?.shopName);
    const shopAddress = str(req.data?.shopAddress);
    const vendorImage = str(req.data?.vendorImage);
    const shopLogo = str(req.data?.shopLogo);

    if (!firstName || !lastName) {
      throw new HttpsError("invalid-argument", "First and last name are required.");
    }
    if (phone.length < 10) {
      throw new HttpsError("invalid-argument", "Valid phone number is required.");
    }
    if (!email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email is required.");
    }
    if (password.length < 8) {
      throw new HttpsError("invalid-argument", "Password must be at least 8 characters.");
    }
    if (!shopName || !shopAddress) {
      throw new HttpsError("invalid-argument", "Shop name and address are required.");
    }
    if (!vendorImage || !shopLogo) {
      throw new HttpsError("invalid-argument", "Vendor image and shop logo are required.");
    }

    const pendingSnap = await db
      .collection("vendor_requests")
      .where("email", "==", email)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    if (!pendingSnap.empty) {
      throw new HttpsError(
        "already-exists",
        "A signup request for this email is already pending approval."
      );
    }

    const vendorSnap = await db
      .collection("vendors")
      .where("email", "==", email)
      .limit(1)
      .get();
    if (!vendorSnap.empty) {
      throw new HttpsError("already-exists", "A vendor with this email already exists.");
    }

    try {
      await admin.auth().getUserByEmail(email);
      throw new HttpsError(
        "already-exists",
        "An account with this email already exists. Try logging in."
      );
    } catch (e: unknown) {
      const err = e as { code?: string };
      if (err.code !== "auth/user-not-found") {
        if (e instanceof HttpsError) throw e;
      }
    }

    const ref = await db.collection("vendor_requests").add({
      firstName,
      lastName,
      phone,
      email,
      password,
      shopName,
      shopAddress,
      vendorImage,
      shopLogo,
      status: "pending",
      isApproved: false,
      isBlocked: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    logger.info(`[submitVendorRequest] created requestId=${ref.id} email=${email}`);
    return { success: true, requestId: ref.id };
  }
);

/** Admin approves request → Firebase Auth + vendors/{uid}. */
export const adminApproveVendorRequest = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const requestId = str(req.data?.requestId);
    if (!requestId) {
      throw new HttpsError("invalid-argument", "requestId is required.");
    }

    const reqRef = db.collection("vendor_requests").doc(requestId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Vendor request not found.");
    }

    const data = reqSnap.data()!;
    const status = str(data.status);
    if (status === "approved") {
      throw new HttpsError("failed-precondition", "Request is already approved.");
    }
    if (status === "rejected") {
      throw new HttpsError("failed-precondition", "Request was rejected.");
    }

    const email = str(data.email).toLowerCase();
    const password = passwordRaw(data.password);
    const firstName = str(data.firstName);
    const lastName = str(data.lastName);
    const shopName = str(data.shopName);
    const shopAddress = str(data.shopAddress);
    const phone = str(data.phone);
    const vendorImage = str(data.vendorImage);
    const shopLogo = str(data.shopLogo);

    let uid: string;
    try {
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: `${firstName} ${lastName}`.trim() || shopName,
      });
      uid = userRecord.uid;
    } catch (e: unknown) {
      const err = e as { code?: string; message?: string };
      if (err.code === "auth/email-already-exists") {
        const existing = await admin.auth().getUserByEmail(email);
        uid = existing.uid;
        await admin.auth().updateUser(uid, { password });
      } else if (err.code === "auth/invalid-password") {
        throw new HttpsError("invalid-argument", "Password is too weak.");
      } else if (err.code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "Invalid email address.");
      } else {
        throw new HttpsError(
          "failed-precondition",
          err.message ?? "Firebase Auth creation failed."
        );
      }
    }

    try {
      await createApprovedVendorProfile({
        uid,
        email,
        password,
        firstName,
        lastName,
        storeName: shopName,
        phone,
        shopAddress,
        vendorImage,
        shopImage: shopLogo,
      });

      await reqRef.update({
        status: "approved",
        isApproved: true,
        approvedAt: FieldValue.serverTimestamp(),
        approvedBy: req.auth?.uid ?? "",
        authUid: uid,
        vendorDocPath: `vendors/${uid}`,
        password: FieldValue.delete(),
      });

      await writeActivityLog({
        action: "approve_vendor_request",
        entityType: "vendor_request",
        entityId: requestId,
        summary: `Approved vendor signup ${email}`,
        metadata: { authUid: uid, email, shopName },
      });

      return {
        success: true,
        authUid: uid,
        firestorePath: `vendors/${uid}`,
      };
    } catch (e) {
      logger.error("[adminApproveVendorRequest] firestore failed", e);
      await admin.auth().deleteUser(uid).catch(() => undefined);
      throw new HttpsError(
        "failed-precondition",
        "Could not complete vendor approval. Auth user was rolled back."
      );
    }
  }
);

/** Admin rejects signup request. */
export const adminRejectVendorRequest = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const requestId = str(req.data?.requestId);
    const reason = str(req.data?.reason) || "Rejected by admin";
    if (!requestId) {
      throw new HttpsError("invalid-argument", "requestId is required.");
    }

    const reqRef = db.collection("vendor_requests").doc(requestId);
    const reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Vendor request not found.");
    }

    await reqRef.update({
      status: "rejected",
      isApproved: false,
      rejectedAt: FieldValue.serverTimestamp(),
      rejectedBy: req.auth?.uid ?? "",
      rejectionReason: reason,
      password: FieldValue.delete(),
    });

    await writeActivityLog({
      action: "reject_vendor_request",
      entityType: "vendor_request",
      entityId: requestId,
      summary: `Rejected vendor signup: ${reason}`,
      metadata: { requestId, reason },
    });

    return { success: true };
  }
);

/** Admin blocks vendor linked to an approved request. */
export const adminBlockVendorFromRequest = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const requestId = str(req.data?.requestId);
    if (!requestId) {
      throw new HttpsError("invalid-argument", "requestId is required.");
    }

    const reqSnap = await db.collection("vendor_requests").doc(requestId).get();
    if (!reqSnap.exists) {
      throw new HttpsError("not-found", "Vendor request not found.");
    }

    const data = reqSnap.data()!;
    const authUid = str(data.authUid);
    if (!authUid) {
      throw new HttpsError("failed-precondition", "Vendor was not approved yet.");
    }

    await db.collection("vendors").doc(authUid).update({
      isBlocked: true,
      is_active: false,
      isApproved: false,
      status: "blocked",
    });

    await db.collection("vendor_requests").doc(requestId).update({
      isBlocked: true,
      status: "blocked",
      blockedAt: FieldValue.serverTimestamp(),
    });

    await admin.auth().updateUser(authUid, { disabled: true }).catch(() => undefined);

    return { success: true };
  }
);
