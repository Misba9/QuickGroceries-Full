/** Firestore path: `app_settings/cod_convenience_fee` */
export const COD_FEE_SETTINGS_PATH = "app_settings/cod_convenience_fee";
export const COD_FEE_AUDIT_COL = "cod_convenience_fee_audit_logs";

export type CodFeeApplicableTo =
  | "all"
  | "users"
  | "cities"
  | "vendors"
  | "categories";

export interface CodConvenienceFeeSettings {
  codFeeEnabled: boolean;
  /** Flat fee in ₹ (e.g. 5, 10, 15). */
  codFeeAmount: number;
  /** Fee applies only when taxable item total ≥ this (0 = no min). */
  minimumOrderAmount: number;
  /** Fee applies only when taxable item total ≤ this (0 = no max). */
  maximumOrderAmount: number;
  /** Waive fee when taxable item total ≥ this (0 = disabled). */
  freeCodAboveAmount: number;
  feeDescription: string;
  applicableTo: CodFeeApplicableTo;
  applicableUsers: string[];
  applicableCities: string[];
  applicableVendors: string[];
  applicableCategories: string[];
  updatedBy: string;
  updatedByName: string;
}

export const DEFAULT_COD_FEE_SETTINGS: CodConvenienceFeeSettings = {
  codFeeEnabled: false,
  codFeeAmount: 10,
  minimumOrderAmount: 0,
  maximumOrderAmount: 0,
  freeCodAboveAmount: 0,
  feeDescription: "Convenience Fee for Cash on Delivery",
  applicableTo: "all",
  applicableUsers: [],
  applicableCities: [],
  applicableVendors: [],
  applicableCategories: [],
  updatedBy: "",
  updatedByName: "",
};

export interface CodFeeCalcContext {
  paymentMethod: string;
  /** Item total after coupon (taxable / free-delivery base). */
  orderAmount: number;
  userId?: string;
  city?: string;
  vendorIds?: string[];
  categories?: string[];
}

export interface CodFeeCalcResult {
  fee: number;
  applied: boolean;
  reason: string;
  description: string;
}
