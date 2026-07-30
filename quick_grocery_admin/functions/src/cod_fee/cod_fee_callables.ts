import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  calculateCodConvenienceFee,
} from "./cod_fee_engine";
import {
  getCodFeeSettings,
  parseCodFeeSettings,
  settingsToClientPayload,
  settingsToFirestore,
  settingsToMainMirror,
} from "./cod_fee_settings";
import {
  COD_FEE_AUDIT_COL,
  COD_FEE_SETTINGS_PATH,
  CodConvenienceFeeSettings,
  CodFeeApplicableTo,
  DEFAULT_COD_FEE_SETTINGS,
} from "./cod_fee_types";

const db = admin.firestore();

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function str(v: unknown, fallback = ""): string {
  if (v == null) return fallback;
  const s = String(v).trim();
  return s || fallback;
}

function strList(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  return v.map((x) => str(x)).filter(Boolean);
}

function parseApplicableTo(v: unknown): CodFeeApplicableTo {
  const s = str(v, "all").toLowerCase();
  if (
    s === "users" ||
    s === "cities" ||
    s === "vendors" ||
    s === "categories"
  ) {
    return s;
  }
  return "all";
}

function rulesSnapshot(s: CodConvenienceFeeSettings): Record<string, unknown> {
  return {
    codFeeEnabled: s.codFeeEnabled,
    codFeeAmount: s.codFeeAmount,
    minimumOrderAmount: s.minimumOrderAmount,
    maximumOrderAmount: s.maximumOrderAmount,
    freeCodAboveAmount: s.freeCodAboveAmount,
    feeDescription: s.feeDescription,
    applicableTo: s.applicableTo,
    applicableUsers: s.applicableUsers,
    applicableCities: s.applicableCities,
    applicableVendors: s.applicableVendors,
    applicableCategories: s.applicableCategories,
  };
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

function parseIncomingSettings(
  raw: Record<string, unknown>,
): CodConvenienceFeeSettings {
  const amount = Math.max(0, num(raw.codFeeAmount, DEFAULT_COD_FEE_SETTINGS.codFeeAmount));
  const min = Math.max(0, num(raw.minimumOrderAmount, 0));
  const max = Math.max(0, num(raw.maximumOrderAmount, 0));
  const freeAbove = Math.max(0, num(raw.freeCodAboveAmount, 0));

  if (max > 0 && min > 0 && max < min) {
    throw new HttpsError(
      "invalid-argument",
      "Maximum order amount must be ≥ minimum order amount.",
    );
  }

  return {
    codFeeEnabled: raw.codFeeEnabled === true,
    codFeeAmount: amount,
    minimumOrderAmount: min,
    maximumOrderAmount: max,
    freeCodAboveAmount: freeAbove,
    feeDescription: str(
      raw.feeDescription,
      DEFAULT_COD_FEE_SETTINGS.feeDescription,
    ),
    applicableTo: parseApplicableTo(raw.applicableTo),
    applicableUsers: strList(raw.applicableUsers),
    applicableCities: strList(raw.applicableCities),
    applicableVendors: strList(raw.applicableVendors),
    applicableCategories: strList(raw.applicableCategories),
    updatedBy: "",
    updatedByName: "",
  };
}

/** GET-equivalent: returns current COD fee / payment settings for admin. */
export const getPaymentSettingsCallable = onCall(
  { region: "us-central1" },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const settings = await getCodFeeSettings();
    return {
      codConvenienceFee: {
        ...settingsToClientPayload(settings),
        updatedBy: settings.updatedBy,
        updatedByName: settings.updatedByName,
      },
    };
  },
);

/** PUT-equivalent: admin updates COD convenience fee settings + audit log. */
export const updatePaymentSettingsCallable = onCall(
  { region: "us-central1" },
  async (request) => {
    await assertNotificationAdmin(request.auth?.uid);
    const adminUid = request.auth!.uid;
    const adminName = await resolveAdminName(adminUid);

    const raw = (request.data ?? {}) as Record<string, unknown>;
    const codRaw =
      (raw.codConvenienceFee as Record<string, unknown> | undefined) ?? raw;
    const next = parseIncomingSettings(codRaw);

    const prev = await getCodFeeSettings();
    const write = settingsToFirestore(next, adminUid, adminName);
    const mirror = settingsToMainMirror({
      ...next,
      updatedBy: adminUid,
      updatedByName: adminName,
    });

    const batch = db.batch();
    batch.set(db.doc(COD_FEE_SETTINGS_PATH), write, { merge: true });
    batch.set(db.doc("settings/main"), {
      ...mirror,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    batch.set(db.collection(COD_FEE_AUDIT_COL).doc(), {
      adminUid,
      adminName,
      previousFee: prev.codFeeAmount,
      newFee: next.codFeeAmount,
      previousRules: rulesSnapshot(prev),
      newRules: rulesSnapshot(next),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return {
      ok: true,
      codConvenienceFee: {
        ...settingsToClientPayload({
          ...next,
          updatedBy: adminUid,
          updatedByName: adminName,
        }),
        updatedBy: adminUid,
        updatedByName: adminName,
      },
    };
  },
);

/**
 * Preview fee for checkout (authenticated user).
 * Optional — clients can also compute from Firestore settings; server is source of truth at place-order.
 */
export const previewCodFeeCallable = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const data = (request.data ?? {}) as Record<string, unknown>;
    const settings = await getCodFeeSettings();
    const result = calculateCodConvenienceFee(settings, {
      paymentMethod: str(data.paymentMethod, "cod"),
      orderAmount: num(data.orderAmount, 0),
      userId: request.auth.uid,
      city: str(data.city),
      vendorIds: strList(data.vendorIds),
      categories: strList(data.categories),
    });
    return {
      fee: result.fee,
      applied: result.applied,
      reason: result.reason,
      description: result.description,
      settings: settingsToClientPayload(settings),
    };
  },
);

/** Used by place-order after a direct Firestore write path if needed. */
export { parseCodFeeSettings, getCodFeeSettings };
