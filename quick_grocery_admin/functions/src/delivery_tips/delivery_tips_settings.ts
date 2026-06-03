import * as admin from "firebase-admin";
import {
  DEFAULT_DELIVERY_TIP_SETTINGS,
  DELIVERY_TIPS_SETTINGS_PATH,
  DeliveryTipSettings,
} from "./delivery_tips_types";

const db = admin.firestore();

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

export async function getDeliveryTipSettings(): Promise<DeliveryTipSettings> {
  const snap = await db.doc(DELIVERY_TIPS_SETTINGS_PATH).get();
  if (!snap.exists) return { ...DEFAULT_DELIVERY_TIP_SETTINGS };
  const data = snap.data() ?? {};
  const rawTips = data.suggestedTips ?? data.suggested_tips;
  const suggestedTips = Array.isArray(rawTips)
    ? rawTips.map((t) => Math.round(num(t))).filter((t) => t > 0)
    : DEFAULT_DELIVERY_TIP_SETTINGS.suggestedTips;
  return {
    enabled: data.enabled !== false,
    suggestedTips:
      suggestedTips.length > 0
        ? suggestedTips
        : DEFAULT_DELIVERY_TIP_SETTINGS.suggestedTips,
    maxTipAmount: Math.max(
      1,
      num(data.maxTipAmount ?? data.max_tip_amount, DEFAULT_DELIVERY_TIP_SETTINGS.maxTipAmount),
    ),
  };
}

export function settingsToFirestore(
  settings: DeliveryTipSettings,
): Record<string, unknown> {
  return {
    enabled: settings.enabled,
    suggestedTips: settings.suggestedTips,
    maxTipAmount: settings.maxTipAmount,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}
