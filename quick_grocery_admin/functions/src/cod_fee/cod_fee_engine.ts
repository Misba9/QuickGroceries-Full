import {
  CodConvenienceFeeSettings,
  CodFeeCalcContext,
  CodFeeCalcResult,
} from "./cod_fee_types";

function norm(v: string | undefined | null): string {
  return (v ?? "").trim().toLowerCase();
}

function listNorm(list: string[]): Set<string> {
  return new Set(list.map((x) => norm(x)).filter(Boolean));
}

function targetingMatches(
  settings: CodConvenienceFeeSettings,
  ctx: CodFeeCalcContext,
): boolean {
  switch (settings.applicableTo) {
    case "all":
      return true;
    case "users": {
      if (settings.applicableUsers.length === 0) return false;
      const uid = norm(ctx.userId);
      return uid.length > 0 && listNorm(settings.applicableUsers).has(uid);
    }
    case "cities": {
      if (settings.applicableCities.length === 0) return false;
      const city = norm(ctx.city);
      return city.length > 0 && listNorm(settings.applicableCities).has(city);
    }
    case "vendors": {
      if (settings.applicableVendors.length === 0) return false;
      const allowed = listNorm(settings.applicableVendors);
      const vendors = (ctx.vendorIds ?? []).map(norm).filter(Boolean);
      return vendors.some((v) => allowed.has(v));
    }
    case "categories": {
      if (settings.applicableCategories.length === 0) return false;
      const allowed = listNorm(settings.applicableCategories);
      const cats = (ctx.categories ?? []).map(norm).filter(Boolean);
      return cats.some((c) => allowed.has(c));
    }
    default:
      return true;
  }
}

/**
 * Server-side COD convenience fee calculator.
 * Never trust the client fee — always recompute with this.
 */
export function calculateCodConvenienceFee(
  settings: CodConvenienceFeeSettings,
  ctx: CodFeeCalcContext,
): CodFeeCalcResult {
  const description =
    settings.feeDescription.trim() || "COD Convenience Fee";

  if (norm(ctx.paymentMethod) !== "cod") {
    return {
      fee: 0,
      applied: false,
      reason: "not_cod",
      description,
    };
  }

  if (!settings.codFeeEnabled) {
    return {
      fee: 0,
      applied: false,
      reason: "disabled",
      description,
    };
  }

  const amount = Math.max(0, Number(ctx.orderAmount) || 0);
  const feeAmount = Math.max(0, Number(settings.codFeeAmount) || 0);

  if (feeAmount <= 0) {
    return {
      fee: 0,
      applied: false,
      reason: "zero_fee",
      description,
    };
  }

  if (
    settings.minimumOrderAmount > 0 &&
    amount < settings.minimumOrderAmount
  ) {
    return {
      fee: 0,
      applied: false,
      reason: "below_minimum",
      description,
    };
  }

  if (
    settings.maximumOrderAmount > 0 &&
    amount > settings.maximumOrderAmount
  ) {
    return {
      fee: 0,
      applied: false,
      reason: "above_maximum",
      description,
    };
  }

  if (
    settings.freeCodAboveAmount > 0 &&
    amount >= settings.freeCodAboveAmount
  ) {
    return {
      fee: 0,
      applied: false,
      reason: "free_cod_threshold",
      description,
    };
  }

  if (!targetingMatches(settings, ctx)) {
    return {
      fee: 0,
      applied: false,
      reason: "not_applicable_audience",
      description,
    };
  }

  const fee = Math.round(feeAmount * 100) / 100;
  return {
    fee,
    applied: fee > 0,
    reason: "applied",
    description,
  };
}

/**
 * Merge server-computed COD fee into the bill.
 * Strips any client-supplied fee first to prevent double-counting / bypass.
 */
export function mergeCodFeeIntoBill(
  bill: Record<string, unknown>,
  fee: number,
  description: string,
): Record<string, unknown> {
  const previousFee = num(bill.codConvenienceFee ?? bill.codFee);
  const baseTotal = num(bill.total ?? bill.grandTotal);
  const withoutPrevious = baseTotal - previousFee;
  const nextFee = Math.max(0, Math.round(fee * 100) / 100);
  const rounded =
    Math.round((withoutPrevious + nextFee) * 100) / 100;

  const next: Record<string, unknown> = {
    ...bill,
    codConvenienceFee: nextFee,
    codFee: nextFee,
    codFeeDescription: description,
    total: rounded,
    grandTotal: rounded,
  };

  if (nextFee <= 0) {
    delete next.codFeeDescription;
  }

  return next;
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

/** Reject when client COD fee / total does not match server (±₹0.05). */
export function assertBillTotalMatches(
  clientBill: Record<string, unknown>,
  serverBill: Record<string, unknown>,
): void {
  const clientFee = num(clientBill.codConvenienceFee ?? clientBill.codFee);
  const serverFee = num(serverBill.codConvenienceFee ?? serverBill.codFee);
  if (Math.abs(clientFee - serverFee) > 0.05) {
    const err = new Error(
      `COD convenience fee mismatch. Expected ₹${serverFee.toFixed(2)}, got ₹${clientFee.toFixed(2)}. Please refresh and try again.`,
    );
    (err as Error & { code?: string }).code = "cod-fee-mismatch";
    throw err;
  }

  const clientTotal = num(clientBill.total ?? clientBill.grandTotal);
  const serverTotal = num(serverBill.total ?? serverBill.grandTotal);
  // Allow small float drift; also tolerate clients that omit tip from tipAmount
  // but already baked tip into the bill — tip merge is tip-idempotent.
  if (Math.abs(clientTotal - serverTotal) > 0.05) {
    const err = new Error(
      `Order total mismatch. Expected ₹${serverTotal.toFixed(2)}, got ₹${clientTotal.toFixed(2)}. Please refresh and try again.`,
    );
    (err as Error & { code?: string }).code = "total-mismatch";
    throw err;
  }
}
