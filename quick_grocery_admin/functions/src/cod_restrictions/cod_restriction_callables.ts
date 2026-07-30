import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  clearedRestrictionWrite,
  parseCodPaymentRestriction,
  resolveCodEligibility,
  restrictionToClientPayload,
  restrictionToFirestoreWrite,
} from "./cod_restriction_engine";
import {
  COD_RESTRICTION_AUDIT_COL,
  CodPaymentRestriction,
  CodRestrictionType,
  DEFAULT_COD_PAYMENT_RESTRICTION,
} from "./cod_restriction_types";

const db = admin.firestore();

function str(v: unknown, fallback = ""): string {
  if (v == null) return fallback;
  const s = String(v).trim();
  return s || fallback;
}

function parseType(v: unknown): CodRestrictionType {
  const s = str(v, "none").toLowerCase();
  if (s === "temporary" || s === "permanent" || s === "none") return s;
  throw new HttpsError(
    "invalid-argument",
    "codRestrictionType must be none, temporary, or permanent.",
  );
}

function toDateOrNull(v: unknown): Date | null {
  if (v == null || v === "") return null;
  if (typeof v === "string") {
    const d = new Date(v);
    if (Number.isNaN(d.getTime())) {
      throw new HttpsError("invalid-argument", "Invalid date value.");
    }
    return d;
  }
  if (typeof v === "number" && Number.isFinite(v)) return new Date(v);
  throw new HttpsError("invalid-argument", "Invalid date value.");
}

async function resolveAdminName(uid: string): Promise<string> {
  try {
    const snap = await db.collection("admins").doc(uid).get();
    if (snap.exists) {
      const d = snap.data() ?? {};
      const name = str(d.name ?? d.displayName ?? d.email);
      if (name) return name;
    }
  } catch {
    // ignore
  }
  try {
    const user = await admin.auth().getUser(uid);
    return user.displayName || user.email || uid;
  } catch {
    return uid;
  }
}

function snapshotStatus(r: CodPaymentRestriction): Record<string, unknown> {
  return {
    codEnabled: r.codEnabled,
    codRestrictionType: r.codRestrictionType,
    codRestrictionReason: r.codRestrictionReason,
    codRestrictionNotes: r.codRestrictionNotes,
    codRestrictionStart: r.codRestrictionStart?.toISOString() ?? null,
    codRestrictionEnd: r.codRestrictionEnd?.toISOString() ?? null,
  };
}

async function loadCustomer(
  userId: string,
): Promise<{ ref: FirebaseFirestore.DocumentReference; data: Record<string, unknown> }> {
  const ref = db.collection("customers").doc(userId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Customer not found.");
  }
  return { ref, data: (snap.data() ?? {}) as Record<string, unknown> };
}

async function writeAudit(params: {
  adminUid: string;
  adminName: string;
  userId: string;
  userName: string;
  oldStatus: Record<string, unknown>;
  newStatus: Record<string, unknown>;
  reason: string;
  action: string;
}): Promise<void> {
  await db.collection(COD_RESTRICTION_AUDIT_COL).add({
    adminUid: params.adminUid,
    adminName: params.adminName,
    userId: params.userId,
    userName: params.userName,
    oldStatus: params.oldStatus,
    newStatus: params.newStatus,
    reason: params.reason,
    action: params.action,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/** GET /admin/users/:id/payment-restrictions */
export const getCustomerPaymentRestrictionsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const userId = str(request.data?.userId ?? request.data?.id);
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    const { ref, data } = await loadCustomer(userId);
    const parsed = parseCodPaymentRestriction(data);
    const eligibility = resolveCodEligibility(parsed);

    // Lazy clear expired temporary restriction so apps see COD again immediately.
    if (eligibility.expired) {
      await ref.set(
        clearedRestrictionWrite("system", "Auto-expiry"),
        { merge: true },
      );
      await writeAudit({
        adminUid: "system",
        adminName: "Auto-expiry",
        userId,
        userName: str(data.name ?? data.email ?? userId),
        oldStatus: snapshotStatus(parsed),
        newStatus: snapshotStatus(DEFAULT_COD_PAYMENT_RESTRICTION),
        reason: "Temporary COD restriction expired",
        action: "auto_expire",
      });
    }

    const historySnap = await db
      .collection(COD_RESTRICTION_AUDIT_COL)
      .where("userId", "==", userId)
      .orderBy("createdAt", "desc")
      .limit(50)
      .get()
      .catch(() => null);

    const history =
      historySnap?.docs.map((d) => {
        const h = d.data();
        const createdAt = h.createdAt as admin.firestore.Timestamp | undefined;
        return {
          id: d.id,
          ...h,
          createdAt: createdAt?.toDate?.()?.toISOString?.() ?? null,
        };
      }) ?? [];

    return {
      userId,
      paymentRestrictions: restrictionToClientPayload(eligibility),
      history,
    };
  },
);

/** PUT /admin/users/:id/payment-restrictions */
export const updateCustomerPaymentRestrictionsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const adminUid = request.auth!.uid;
    const adminName = await resolveAdminName(adminUid);

    const userId = str(request.data?.userId ?? request.data?.id);
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    const type = parseType(request.data?.codRestrictionType);
    const reason = str(request.data?.codRestrictionReason ?? request.data?.reason);
    const notes = str(
      request.data?.codRestrictionNotes ?? request.data?.notes,
    );

    if (type !== "none" && !reason) {
      throw new HttpsError(
        "invalid-argument",
        "Reason is required when restricting COD.",
      );
    }

    let start = toDateOrNull(
      request.data?.codRestrictionStart ?? request.data?.startDate,
    );
    let end = toDateOrNull(
      request.data?.codRestrictionEnd ?? request.data?.endDate,
    );

    if (type === "temporary") {
      if (!end) {
        throw new HttpsError(
          "invalid-argument",
          "End date is required for temporary COD restrictions.",
        );
      }
      start = start ?? new Date();
      if (end.getTime() <= start.getTime()) {
        throw new HttpsError(
          "invalid-argument",
          "End date must be after start date.",
        );
      }
    }
    if (type === "permanent") {
      start = start ?? new Date();
      end = null;
    }
    if (type === "none") {
      start = null;
      end = null;
    }

    const next: CodPaymentRestriction = {
      codEnabled: type === "none",
      codRestrictionType: type,
      codRestrictionReason: type === "none" ? "" : reason,
      codRestrictionNotes: notes,
      codRestrictionStart: start,
      codRestrictionEnd: end,
      codRestrictedBy: adminUid,
      codRestrictedByName: adminName,
      codUpdatedAt: new Date(),
    };

    const { ref, data } = await loadCustomer(userId);
    const prev = parseCodPaymentRestriction(data);

    const write =
      type === "none"
        ? clearedRestrictionWrite(adminUid, adminName)
        : restrictionToFirestoreWrite(next, adminUid, adminName);

    // Mirror onto users/{uid} when present (profile dual-write pattern).
    const batch = db.batch();
    batch.set(ref, write, { merge: true });
    const usersRef = db.collection("users").doc(userId);
    batch.set(usersRef, write, { merge: true });
    await batch.commit();

    await writeAudit({
      adminUid,
      adminName,
      userId,
      userName: str(data.name ?? data.email ?? userId),
      oldStatus: snapshotStatus(prev),
      newStatus: snapshotStatus(next),
      reason: next.codRestrictionReason || "Restriction removed",
      action: type === "none" ? "remove" : "update",
    });

    const eligibility = resolveCodEligibility(next);
    return {
      ok: true,
      userId,
      paymentRestrictions: restrictionToClientPayload(eligibility),
    };
  },
);

/** DELETE /admin/users/:id/payment-restrictions */
export const deleteCustomerPaymentRestrictionsCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const adminUid = request.auth!.uid;
    const adminName = await resolveAdminName(adminUid);
    const userId = str(request.data?.userId ?? request.data?.id);
    if (!userId) {
      throw new HttpsError("invalid-argument", "userId is required.");
    }

    const { ref, data } = await loadCustomer(userId);
    const prev = parseCodPaymentRestriction(data);
    const write = clearedRestrictionWrite(adminUid, adminName);

    const batch = db.batch();
    batch.set(ref, write, { merge: true });
    batch.set(db.collection("users").doc(userId), write, { merge: true });
    await batch.commit();

    await writeAudit({
      adminUid,
      adminName,
      userId,
      userName: str(data.name ?? data.email ?? userId),
      oldStatus: snapshotStatus(prev),
      newStatus: snapshotStatus(DEFAULT_COD_PAYMENT_RESTRICTION),
      reason: str(request.data?.reason, "Restriction removed by admin"),
      action: "remove",
    });

    return {
      ok: true,
      userId,
      paymentRestrictions: restrictionToClientPayload(
        resolveCodEligibility(DEFAULT_COD_PAYMENT_RESTRICTION),
      ),
    };
  },
);

/**
 * List customers with active COD restrictions (admin browse page).
 * Query: customers where codEnabled == false.
 */
export const listCodRestrictedCustomersCallable = onCall(
  { ...callableBaseOptions() },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const limit = Math.min(
      200,
      Math.max(1, Number(request.data?.limit) || 100),
    );

    const snap = await db
      .collection("customers")
      .where("codEnabled", "==", false)
      .limit(limit)
      .get();

    const now = new Date();
    const items = [];
    for (const doc of snap.docs) {
      const data = doc.data() as Record<string, unknown>;
      const parsed = parseCodPaymentRestriction(data);
      const eligibility = resolveCodEligibility(parsed, now);
      if (eligibility.expired) {
        // Clear in background; still skip from restricted list.
        void doc.ref.set(
          clearedRestrictionWrite("system", "Auto-expiry"),
          { merge: true },
        );
        continue;
      }
      if (eligibility.allowed) continue;
      items.push({
        userId: doc.id,
        name: str(data.name),
        phone: str(data.phone ?? data.phoneNumber),
        email: str(data.email),
        paymentRestrictions: restrictionToClientPayload(eligibility),
      });
    }

    return { items };
  },
);
