import * as admin from "firebase-admin";
import {
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
  return v
    .map((x) => str(x))
    .filter((x) => x.length > 0);
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

export function parseCodFeeSettings(
  data: Record<string, unknown> | undefined | null,
): CodConvenienceFeeSettings {
  if (!data || Object.keys(data).length === 0) {
    return { ...DEFAULT_COD_FEE_SETTINGS };
  }
  return {
    codFeeEnabled: data.codFeeEnabled === true || data.cod_fee_enabled === true,
    codFeeAmount: Math.max(
      0,
      num(data.codFeeAmount ?? data.cod_fee_amount, DEFAULT_COD_FEE_SETTINGS.codFeeAmount),
    ),
    minimumOrderAmount: Math.max(
      0,
      num(data.minimumOrderAmount ?? data.minimum_order_amount, 0),
    ),
    maximumOrderAmount: Math.max(
      0,
      num(data.maximumOrderAmount ?? data.maximum_order_amount, 0),
    ),
    freeCodAboveAmount: Math.max(
      0,
      num(data.freeCodAboveAmount ?? data.free_cod_above_amount, 0),
    ),
    feeDescription: str(
      data.feeDescription ?? data.fee_description,
      DEFAULT_COD_FEE_SETTINGS.feeDescription,
    ),
    applicableTo: parseApplicableTo(data.applicableTo ?? data.applicable_to),
    applicableUsers: strList(data.applicableUsers ?? data.applicable_users),
    applicableCities: strList(data.applicableCities ?? data.applicable_cities),
    applicableVendors: strList(data.applicableVendors ?? data.applicable_vendors),
    applicableCategories: strList(
      data.applicableCategories ?? data.applicable_categories,
    ),
    updatedBy: str(data.updatedBy ?? data.updated_by),
    updatedByName: str(data.updatedByName ?? data.updated_by_name),
  };
}

export async function getCodFeeSettings(): Promise<CodConvenienceFeeSettings> {
  const snap = await db.doc(COD_FEE_SETTINGS_PATH).get();
  if (!snap.exists) return { ...DEFAULT_COD_FEE_SETTINGS };
  return parseCodFeeSettings(snap.data() as Record<string, unknown>);
}

/** Public / client-safe subset (no admin identity). */
export function settingsToClientPayload(
  settings: CodConvenienceFeeSettings,
): Record<string, unknown> {
  return {
    codFeeEnabled: settings.codFeeEnabled,
    codFeeAmount: settings.codFeeAmount,
    minimumOrderAmount: settings.minimumOrderAmount,
    maximumOrderAmount: settings.maximumOrderAmount,
    freeCodAboveAmount: settings.freeCodAboveAmount,
    feeDescription: settings.feeDescription,
    applicableTo: settings.applicableTo,
    applicableUsers: settings.applicableUsers,
    applicableCities: settings.applicableCities,
    applicableVendors: settings.applicableVendors,
    applicableCategories: settings.applicableCategories,
  };
}

/** Fields mirrored onto `settings/main` for PricingService realtime merge. */
export function settingsToMainMirror(
  settings: CodConvenienceFeeSettings,
): Record<string, unknown> {
  return {
    codFeeEnabled: settings.codFeeEnabled,
    codFeeAmount: settings.codFeeAmount,
    codFeeMinimumOrderAmount: settings.minimumOrderAmount,
    codFeeMaximumOrderAmount: settings.maximumOrderAmount,
    freeCodAboveAmount: settings.freeCodAboveAmount,
    codFeeDescription: settings.feeDescription,
    codFeeApplicableTo: settings.applicableTo,
    codFeeApplicableUsers: settings.applicableUsers,
    codFeeApplicableCities: settings.applicableCities,
    codFeeApplicableVendors: settings.applicableVendors,
    codFeeApplicableCategories: settings.applicableCategories,
  };
}

export function settingsToFirestore(
  settings: CodConvenienceFeeSettings,
  adminUid: string,
  adminName: string,
): Record<string, unknown> {
  return {
    codFeeEnabled: settings.codFeeEnabled,
    codFeeAmount: settings.codFeeAmount,
    minimumOrderAmount: settings.minimumOrderAmount,
    maximumOrderAmount: settings.maximumOrderAmount,
    freeCodAboveAmount: settings.freeCodAboveAmount,
    feeDescription: settings.feeDescription,
    applicableTo: settings.applicableTo,
    applicableUsers: settings.applicableUsers,
    applicableCities: settings.applicableCities,
    applicableVendors: settings.applicableVendors,
    applicableCategories: settings.applicableCategories,
    updatedBy: adminUid,
    updatedByName: adminName,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}
