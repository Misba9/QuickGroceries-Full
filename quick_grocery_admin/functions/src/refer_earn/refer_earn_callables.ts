import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callableBaseOptions } from "../https_callable_options";
import { assertNotificationAdmin } from "../notification_admin_assert";
import {
  applyReferralCode,
  disableReferral,
  ensureUserReferralCode,
  getUserReferEarnStats,
  grantReferralRewards,
  rejectReferral,
  resendReferralCoupons,
} from "./refer_earn_engine";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

/** Apply a referral code at signup (authenticated). */
export const applyReferralCodeCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in to apply a referral code.");
    }
    const code = str(req.data?.code);
    if (!code) {
      throw new HttpsError("invalid-argument", "Referral code is required.");
    }
    return applyReferralCode(uid, code);
  }
);

async function dashboardForUser(
  uid: string,
  name?: string
): Promise<Record<string, unknown>> {
  if (name) {
    await ensureUserReferralCode(uid, name);
  }
  return getUserReferEarnStats(uid);
}

/** Dashboard stats for the logged-in user's referral program. */
export const getReferEarnStatsCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    return dashboardForUser(uid, str(req.data?.name) || undefined);
  }
);

/** Alias — same payload as [getReferEarnStatsCallable] (preferred client name). */
export const getReferralDashboard = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    return dashboardForUser(uid, str(req.data?.name) || undefined);
  }
);

/** Ensure referral code exists after profile creation. */
export const ensureReferralCodeCallable = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const code = await ensureUserReferralCode(uid, str(req.data?.name));
    return { referralCode: code };
  }
);

/** Alias for [ensureReferralCodeCallable]. */
export const generateReferralCode = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const code = await ensureUserReferralCode(uid, str(req.data?.name));
    return { referralCode: code };
  }
);

/** Returns referral history for the current user. */
export const getReferralHistory = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const stats = await getUserReferEarnStats(uid);
    return {
      history: stats.history ?? [],
      referralCode: stats.referralCode,
    };
  }
);

/** Builds share invite text (requires Play Store URL in admin settings). */
export const shareReferralInvite = onCall(
  { ...callableBaseOptions(), invoker: "public" },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const stats = await getUserReferEarnStats(uid);
    return {
      shareMessage: stats.shareMessage,
      canShare: stats.canShare,
      referralCode: stats.referralCode,
    };
  }
);

type AdminAction =
  | "approve_reward"
  | "reject_reward"
  | "resend_coupon"
  | "disable_referral";

/** Admin actions on referral records. */
export const adminReferEarnActionCallable = onCall(
  callableBaseOptions(),
  async (req) => {
    await assertNotificationAdmin(req.auth?.uid);
    const action = str(req.data?.action) as AdminAction;
    const referralId = str(req.data?.referralId);
    if (!referralId) {
      throw new HttpsError("invalid-argument", "referralId is required.");
    }

    switch (action) {
      case "approve_reward":
        return grantReferralRewards(referralId, {
          adminUid: req.auth?.uid,
          force: true,
        });
      case "reject_reward":
        return rejectReferral(
          referralId,
          str(req.data?.reason) || "Rejected by admin",
          req.auth?.uid
        );
      case "resend_coupon":
        return resendReferralCoupons(referralId);
      case "disable_referral":
        return disableReferral(referralId);
      default:
        throw new HttpsError("invalid-argument", "Unknown action.");
    }
  }
);
