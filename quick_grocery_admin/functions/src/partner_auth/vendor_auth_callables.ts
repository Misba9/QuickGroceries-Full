import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { db } from "./partner_store";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

/** Check Firebase Auth + Firestore vendor state before password reset / login hints. */
export const vendorCheckAuthForPasswordReset = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const email = str(req.data?.email).toLowerCase();
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email is required.");
    }

    let authExists = false;
    let authUid: string | null = null;
    try {
      const user = await admin.auth().getUserByEmail(email);
      authExists = true;
      authUid = user.uid;
    } catch {
      authExists = false;
    }

    const snap = await db
      .collection("vendors")
      .where("email", "==", email)
      .limit(1)
      .get();
    const firestoreExists = !snap.empty;
    const vendorDocId = snap.empty ? null : snap.docs[0].id;
    const uidMatch =
      authExists && authUid != null && vendorDocId != null && authUid === vendorDocId;

    const pendingSnap = await db
      .collection("vendor_requests")
      .where("email", "==", email)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    const pendingRequest = !pendingSnap.empty;

    return {
      authExists,
      authUid,
      firestoreExists,
      vendorDocId,
      uidMatch,
      firestoreOnly: firestoreExists && !authExists,
      pendingRequest,
    };
  }
);

/** Diagnose login failures (invalid password vs missing Auth vs ID mismatch). */
export const vendorDiagnoseLogin = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const email = str(req.data?.email).toLowerCase();
    if (!email || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "Valid email is required.");
    }

    let authExists = false;
    let authUid: string | null = null;
    try {
      const user = await admin.auth().getUserByEmail(email);
      authExists = true;
      authUid = user.uid;
    } catch {
      authExists = false;
    }

    const snap = await db
      .collection("vendors")
      .where("email", "==", email)
      .limit(1)
      .get();
    const firestoreExists = !snap.empty;
    const vendorDocId = snap.empty ? null : snap.docs[0].id;
    const uidMatch =
      authExists && authUid != null && vendorDocId != null && authUid === vendorDocId;

    const pendingSnap = await db
      .collection("vendor_requests")
      .where("email", "==", email)
      .where("status", "==", "pending")
      .limit(1)
      .get();
    const pendingRequest = !pendingSnap.empty;

    return {
      authExists,
      authUid,
      firestoreExists,
      vendorDocId,
      uidMatch,
      firestoreOnly: firestoreExists && !authExists,
      idMismatch: authExists && firestoreExists && !uidMatch,
      pendingRequest,
    };
  }
);
