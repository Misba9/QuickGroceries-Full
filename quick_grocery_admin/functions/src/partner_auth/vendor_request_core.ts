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

  await db.collection("vendors").doc(opts.uid).set(
    buildSyncedVendorFields({
      uid: opts.uid,
      email: opts.email,
      ownerName,
      storeName: opts.storeName,
      firstName: opts.firstName,
      lastName: opts.lastName,
      passwordHash,
      existing: {
        phone: opts.phone,
        shop_address: opts.shopAddress,
        vendor_image: opts.vendorImage,
        shop_image: opts.shopImage,
        status: "approved",
        isApproved: true,
        isBlocked: false,
        is_active: true,
        createdAt: FieldValue.serverTimestamp(),
      },
    })
  );
}

export async function approveVendorRequestCore(opts: {
  requestId: string;
  adminUid: string;
}): Promise<{ success: true; authUid: string; firestorePath: string }> {
  const requestId = str(opts.requestId);
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }

  logger.info("[approveVendorRequestCore] Vendor approval started", {
    requestId,
    adminUid: opts.adminUid,
  });

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

  if (!email.includes("@")) {
    throw new HttpsError("invalid-argument", "Vendor request email is invalid.");
  }
  if (password.length < 8) {
    throw new HttpsError(
      "invalid-argument",
      "Vendor request password is missing or too short."
    );
  }

  let uid: string;
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`.trim() || shopName,
    });
    uid = userRecord.uid;
    logger.info("[approveVendorRequestCore] Firebase Auth user created", { uid, email });
  } catch (e: unknown) {
    const err = e as { code?: string; message?: string };
    if (err.code === "auth/email-already-in-use" || err.code === "auth/email-already-exists") {
      const existing = await admin.auth().getUserByEmail(email);
      uid = existing.uid;
      await admin.auth().updateUser(uid, { password });
      logger.info("[approveVendorRequestCore] linked existing Auth user", { uid, email });
    } else if (err.code === "auth/invalid-password") {
      throw new HttpsError("invalid-argument", "Password is too weak.");
    } else if (err.code === "auth/invalid-email") {
      throw new HttpsError("invalid-argument", "Invalid email address.");
    } else {
      logger.error("[approveVendorRequestCore] Firebase Auth failed", err);
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
      approvedBy: opts.adminUid,
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

    logger.info("[approveVendorRequestCore] Vendor approval success", {
      requestId,
      authUid: uid,
      firestorePath: `vendors/${uid}`,
    });

    return {
      success: true,
      authUid: uid,
      firestorePath: `vendors/${uid}`,
    };
  } catch (e) {
    logger.error("[approveVendorRequestCore] Vendor approval failed", e);
    await admin.auth().deleteUser(uid).catch(() => undefined);
    throw new HttpsError(
      "failed-precondition",
      "Could not complete vendor approval. Auth user was rolled back."
    );
  }
}

export async function rejectVendorRequestCore(opts: {
  requestId: string;
  adminUid: string;
  reason?: string;
}): Promise<{ success: true }> {
  const requestId = str(opts.requestId);
  const reason = str(opts.reason) || "Rejected by admin";
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId is required.");
  }

  logger.info("[rejectVendorRequestCore] Vendor rejection started", {
    requestId,
    adminUid: opts.adminUid,
  });

  const reqRef = db.collection("vendor_requests").doc(requestId);
  const reqSnap = await reqRef.get();
  if (!reqSnap.exists) {
    throw new HttpsError("not-found", "Vendor request not found.");
  }

  await reqRef.update({
    status: "rejected",
    isApproved: false,
    rejectedAt: FieldValue.serverTimestamp(),
    rejectedBy: opts.adminUid,
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

  logger.info("[rejectVendorRequestCore] Vendor rejection success", { requestId });
  return { success: true };
}
