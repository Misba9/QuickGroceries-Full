/** Per-user COD payment restrictions on `customers/{uid}`. */
export const COD_RESTRICTION_AUDIT_COL = "cod_restriction_audit_logs";

export type CodRestrictionType = "none" | "temporary" | "permanent";

export interface CodPaymentRestriction {
  codEnabled: boolean;
  codRestrictionType: CodRestrictionType;
  codRestrictionReason: string;
  /** Internal admin notes (not shown to customer). */
  codRestrictionNotes: string;
  codRestrictionStart: Date | null;
  codRestrictionEnd: Date | null;
  codRestrictedBy: string;
  codRestrictedByName: string;
  codUpdatedAt: Date | null;
}

export const DEFAULT_COD_PAYMENT_RESTRICTION: CodPaymentRestriction = {
  codEnabled: true,
  codRestrictionType: "none",
  codRestrictionReason: "",
  codRestrictionNotes: "",
  codRestrictionStart: null,
  codRestrictionEnd: null,
  codRestrictedBy: "",
  codRestrictedByName: "",
  codUpdatedAt: null,
};

export interface CodEligibilityResult {
  allowed: boolean;
  /** Effective status after auto-expiry of temporary restrictions. */
  status: "enabled" | "disabled" | "temporary";
  restrictionType: CodRestrictionType;
  reason: string;
  message: string;
  expired: boolean;
  restriction: CodPaymentRestriction;
}
