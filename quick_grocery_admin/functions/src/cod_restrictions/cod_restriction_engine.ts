import * as admin from "firebase-admin";
import {
  CodEligibilityResult,
  CodPaymentRestriction,
  CodRestrictionType,
  DEFAULT_COD_PAYMENT_RESTRICTION,
} from "./cod_restriction_types";

function str(v: unknown, fallback = ""): string {
  if (v == null) return fallback;
  const s = String(v).trim();
  return s || fallback;
}

function parseType(v: unknown): CodRestrictionType {
  const s = str(v, "none").toLowerCase();
  if (s === "temporary" || s === "permanent") return s;
  return "none";
}

function toDate(v: unknown): Date | null {
  if (v == null) return null;
  if (v instanceof Date) return v;
  if (v instanceof admin.firestore.Timestamp) return v.toDate();
  if (typeof (v as { toDate?: () => Date }).toDate === "function") {
    try {
      return (v as { toDate: () => Date }).toDate();
    } catch {
      return null;
    }
  }
  if (typeof v === "string" && v.trim()) {
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  if (typeof v === "number" && Number.isFinite(v)) {
    return new Date(v);
  }
  return null;
}

export function parseCodPaymentRestriction(
  data: Record<string, unknown> | undefined | null,
): CodPaymentRestriction {
  if (!data) return { ...DEFAULT_COD_PAYMENT_RESTRICTION };

  const type = parseType(data.codRestrictionType ?? data.cod_restriction_type);

  // Default: COD enabled unless explicitly restricted.
  let enabled = true;
  if (typeof data.codEnabled === "boolean") {
    enabled = data.codEnabled;
  } else if (typeof data.cod_enabled === "boolean") {
    enabled = data.cod_enabled;
  } else if (type === "temporary" || type === "permanent") {
    enabled = false;
  } else if (data.codDisabled === true || data.cod_disabled === true) {
    enabled = false;
  }

  return {
    codEnabled: enabled,
    codRestrictionType: type,
    codRestrictionReason: str(
      data.codRestrictionReason ?? data.cod_restriction_reason,
    ),
    codRestrictionNotes: str(
      data.codRestrictionNotes ?? data.cod_restriction_notes,
    ),
    codRestrictionStart: toDate(
      data.codRestrictionStart ?? data.cod_restriction_start,
    ),
    codRestrictionEnd: toDate(
      data.codRestrictionEnd ?? data.cod_restriction_end,
    ),
    codRestrictedBy: str(data.codRestrictedBy ?? data.cod_restricted_by),
    codRestrictedByName: str(
      data.codRestrictedByName ?? data.cod_restricted_by_name,
    ),
    codUpdatedAt: toDate(data.codUpdatedAt ?? data.cod_updated_at),
  };
}

/**
 * Resolve whether a customer may use COD right now.
 * Temporary restrictions past `codRestrictionEnd` are treated as expired.
 */
export function resolveCodEligibility(
  raw: CodPaymentRestriction,
  now: Date = new Date(),
): CodEligibilityResult {
  const restriction = { ...raw };

  if (
    restriction.codRestrictionType === "none" ||
    restriction.codEnabled === true
  ) {
    return {
      allowed: true,
      status: "enabled",
      restrictionType: "none",
      reason: "",
      message: "",
      expired: false,
      restriction: {
        ...restriction,
        codEnabled: true,
        codRestrictionType: "none",
      },
    };
  }

  if (restriction.codRestrictionType === "temporary") {
    const end = restriction.codRestrictionEnd;
    if (end && end.getTime() <= now.getTime()) {
      return {
        allowed: true,
        status: "enabled",
        restrictionType: "none",
        reason: "",
        message: "",
        expired: true,
        restriction: {
          ...DEFAULT_COD_PAYMENT_RESTRICTION,
          codUpdatedAt: now,
        },
      };
    }
    return {
      allowed: false,
      status: "temporary",
      restrictionType: "temporary",
      reason: restriction.codRestrictionReason,
      message:
        "Cash on Delivery is unavailable for your account. Please use Online Payment.",
      expired: false,
      restriction,
    };
  }

  // permanent (or disabled without explicit type)
  return {
    allowed: false,
    status: "disabled",
    restrictionType: "permanent",
    reason: restriction.codRestrictionReason,
    message:
      "Cash on Delivery is unavailable for your account. Please use Online Payment.",
    expired: false,
    restriction: {
      ...restriction,
      codRestrictionType: "permanent",
      codEnabled: false,
    },
  };
}

/** Firestore write map clearing a restriction (COD re-enabled). */
export function clearedRestrictionWrite(
  adminUid: string,
  adminName: string,
): Record<string, unknown> {
  return {
    codEnabled: true,
    codRestrictionType: "none",
    codRestrictionReason: "",
    codRestrictionNotes: "",
    codRestrictionStart: null,
    codRestrictionEnd: null,
    codRestrictedBy: adminUid,
    codRestrictedByName: adminName,
    codUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

export function restrictionToFirestoreWrite(
  restriction: CodPaymentRestriction,
  adminUid: string,
  adminName: string,
): Record<string, unknown> {
  const type = restriction.codRestrictionType;
  const enabled = type === "none";
  return {
    codEnabled: enabled,
    codRestrictionType: type,
    codRestrictionReason: restriction.codRestrictionReason.trim(),
    codRestrictionNotes: restriction.codRestrictionNotes.trim(),
    codRestrictionStart:
      type === "none"
        ? null
        : restriction.codRestrictionStart
          ? admin.firestore.Timestamp.fromDate(restriction.codRestrictionStart)
          : admin.firestore.FieldValue.serverTimestamp(),
    codRestrictionEnd:
      type === "temporary" && restriction.codRestrictionEnd
        ? admin.firestore.Timestamp.fromDate(restriction.codRestrictionEnd)
        : null,
    codRestrictedBy: adminUid,
    codRestrictedByName: adminName,
    codUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

export function restrictionToClientPayload(
  eligibility: CodEligibilityResult,
): Record<string, unknown> {
  const r = eligibility.restriction;
  return {
    codEnabled: eligibility.allowed,
    codRestrictionType: eligibility.restrictionType,
    codRestrictionReason: eligibility.reason,
    codRestrictionNotes: r.codRestrictionNotes,
    codRestrictionStart: r.codRestrictionStart?.toISOString() ?? null,
    codRestrictionEnd: r.codRestrictionEnd?.toISOString() ?? null,
    codRestrictedBy: r.codRestrictedBy,
    codRestrictedByName: r.codRestrictedByName,
    codUpdatedAt: r.codUpdatedAt?.toISOString() ?? null,
    status: eligibility.status,
    message: eligibility.message,
    expired: eligibility.expired,
  };
}
