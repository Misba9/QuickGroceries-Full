import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError } from "firebase-functions/v2/https";
import { writeActivityLog } from "../operations/ops_notify";
import { hashPassword } from "./partner_crypto";
import { db } from "./partner_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

/** Password must not be trimmed — must match delivery login input exactly. */
function passwordRaw(v: unknown): string {
  if (v == null) return "";
  return String(v);
}

async function rollbackAuthUser(uid: string): Promise<void> {
  await admin.auth().deleteUser(uid).catch(() => undefined);
}

function buildDeliveryFields(params: {
  uid: string;
  email: string;
  name: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  image: string;
  licenceNumber: string;
  passwordHash: string;
}): Record<string, unknown> {
  const {
    uid,
    email,
    name,
    firstName,
    lastName,
    phone,
    address,
    image,
    licenceNumber,
    passwordHash,
  } = params;

  return {
    uid,
    id: uid,
    auth_uid: uid,
    name,
    first_name: firstName,
    last_name: lastName,
    email,
    phone,
    address,
    image,
    licence_number: licenceNumber,
    licence: licenceNumber,
    password_hash: passwordHash,
    isActive: true,
    is_active: true,
    authSynced: true,
    firebaseAuth: true,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export type CreateDeliveryAccountInput = {
  email: string;
  password: string;
  authUid?: string;
  firstName: string;
  lastName: string;
  phone: string;
  address: string;
  image: string;
  licenceNumber: string;
};

/** Shared create logic for callable + HTTP handlers. */
export async function createDeliveryAccountCore(
  input: CreateDeliveryAccountInput,
  adminUid: string
): Promise<Record<string, unknown>> {
  const email = str(input.email).toLowerCase();
  const password = passwordRaw(input.password);
  const preCreatedAuthUid = str(input.authUid);
  const firstName = str(input.firstName);
  const lastName = str(input.lastName);
  const phone = str(input.phone);
  const address = str(input.address);
  const image = str(input.image);
  const licenceNumber = str(input.licenceNumber);

  logger.info(
    `[createDeliveryAccountCore] admin=${adminUid} email=${email} authUid=${preCreatedAuthUid || "(create)"}`
  );

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
  if (phone.length < 10) {
    throw new HttpsError("invalid-argument", "Valid phone number is required.");
  }

  const existingSnap = await db
    .collection("delivery_boys")
    .where("email", "==", email)
    .limit(1)
    .get();
  if (!existingSnap.empty) {
    const existingId = existingSnap.docs[0].id;
    throw new HttpsError(
      "already-exists",
      `A delivery boy with this email already exists (delivery_boys/${existingId}).`
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
    } catch (e: unknown) {
      const err = e as { code?: string };
      if (err.code === "auth/user-not-found") {
        throw new HttpsError(
          "not-found",
          "Firebase Authentication user not found for authUid."
        );
      }
      throw e;
    }
  } else {
    logger.info("[createDeliveryAccountCore] Creating Firebase Auth user...");
    let userRecord: admin.auth.UserRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: `${firstName} ${lastName}`.trim(),
      });
    } catch (e: unknown) {
      const err = e as { code?: string; message?: string };
      logger.warn("[createDeliveryAccountCore] auth create failed", err);
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

  const name = `${firstName} ${lastName}`.trim();
  logger.info(`[createDeliveryAccountCore] auth uid=${uid} — saving Firestore...`);

  try {
    const existingDoc = await db.collection("delivery_boys").doc(uid).get();
    if (existingDoc.exists) {
      throw new HttpsError(
        "already-exists",
        `Firestore document delivery_boys/${uid} already exists.`
      );
    }

    const passwordHash = await hashPassword(password);
    const riderRef = db.collection("delivery_boys").doc(uid);

    await riderRef.set(
      buildDeliveryFields({
        uid,
        email,
        name,
        firstName,
        lastName,
        phone,
        address,
        image,
        licenceNumber,
        passwordHash,
      })
    );

    await writeActivityLog({
      action: "admin_create_delivery_boy",
      entityType: "delivery_boy",
      entityId: uid,
      summary: `Admin created delivery boy ${email} (${name})`,
      metadata: { email, name, authUid: uid, adminUid },
    });

    logger.info(`[createDeliveryAccountCore] success delivery_boys/${uid}`);

    return {
      success: true,
      authUid: uid,
      deliveryBoyId: uid,
      firestorePath: `delivery_boys/${uid}`,
    };
  } catch (e) {
    logger.error("[createDeliveryAccountCore] firestore write failed", e);
    if (!preCreatedAuthUid) {
      await rollbackAuthUser(uid);
    }
    if (e instanceof HttpsError) throw e;
    const msg =
      e instanceof Error ? e.message : "Delivery boy profile could not be saved.";
    throw new HttpsError(
      "failed-precondition",
      `${msg} Auth user was rolled back.`
    );
  }
}

export { rollbackAuthUser };
