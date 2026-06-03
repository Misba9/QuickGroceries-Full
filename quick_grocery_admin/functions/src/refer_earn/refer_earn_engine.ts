import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { normalizePhone } from "../coupons/coupon_types";
import {
  notifyCustomer,
  writeUserInbox,
} from "../operations/ops_notify";
import {
  DEFAULT_SHARE_MESSAGE_TEMPLATE,
  type CampaignStatus,
  type ReferEarnCampaign,
  type ReferEarnSettings,
  type ReferralHistoryItem,
  type ReferralStatus,
  type RewardStatus,
} from "./refer_earn_types";

const db = admin.firestore();

const SETTINGS_DOC = "refer_earn_settings/global";

function str(v: unknown): string {
  if (v == null) return "";
  return String(v).trim();
}

function num(v: unknown, fallback = 0): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
}

function normalizeCode(code: string): string {
  return code.trim().toUpperCase().replace(/\s+/g, "");
}

function randomSuffix(len = 3): string {
  const digits = "0123456789";
  let s = "";
  for (let i = 0; i < len; i++) {
    s += digits[Math.floor(Math.random() * digits.length)];
  }
  return s;
}

function namePrefix(name: string): string {
  const cleaned = name
    .replace(/[^a-zA-Z0-9]/g, "")
    .toUpperCase()
    .slice(0, 6);
  return cleaned.length >= 2 ? cleaned : "USER";
}

export function referralStatusLabel(status: string): string {
  switch (status) {
    case "pending":
      return "Pending";
    case "first_order_pending":
      return "Joined";
    case "reward_eligible":
      return "First Order Completed";
    case "reward_granted":
      return "Reward Granted";
    case "rejected":
      return "Rejected";
    default:
      return status;
  }
}

export function buildReferralShareMessage(
  settings: ReferEarnSettings,
  campaign: ReferEarnCampaign | null,
  referralCode: string
): string {
  const template =
    str(settings.share_message_template) || DEFAULT_SHARE_MESSAGE_TEMPLATE;
  const friendReward =
    campaign?.new_user_reward_amount ?? settings.new_user_reward_amount;
  const referrerReward =
    campaign?.referrer_reward_amount ?? settings.referrer_reward_amount;
  const minOrder = campaign?.minimum_order_value ?? settings.minimum_order_value;
  const playUrl = str(settings.play_store_url);

  return template
    .replace(/\{code\}/gi, referralCode)
    .replace(/\{friend_reward\}/gi, String(friendReward))
    .replace(/\{referrer_reward\}/gi, String(referrerReward))
    .replace(/\{min_order\}/gi, String(minOrder))
    .replace(/\{play_store_url\}/gi, playUrl);
}

export async function getReferEarnSettings(): Promise<ReferEarnSettings> {
  const snap = await db.doc(SETTINGS_DOC).get();
  const d = snap.data() ?? {};
  const campaign = str(d.active_campaign_id)
    ? await getCampaign(str(d.active_campaign_id))
    : null;

  return {
    enabled: d.enabled === true,
    active_campaign_id: str(d.active_campaign_id),
    play_store_url: str(d.play_store_url),
    share_message_template:
      str(d.share_message_template) || DEFAULT_SHARE_MESSAGE_TEMPLATE,
    referrer_reward_amount: num(
      d.referrer_reward_amount,
      campaign?.referrer_reward_amount ?? 50
    ),
    new_user_reward_amount: num(
      d.new_user_reward_amount,
      campaign?.new_user_reward_amount ?? 50
    ),
    minimum_order_value: num(
      d.minimum_order_value,
      campaign?.minimum_order_value ?? 199
    ),
    coupon_expiry_days: num(
      d.coupon_expiry_days,
      campaign?.referral_validity_days ?? 30
    ),
    max_referrals_per_user: Math.max(
      1,
      num(d.max_referrals_per_user, campaign?.max_referrals_per_user ?? 10)
    ),
    auto_grant_rewards:
      d.auto_grant_rewards !== false &&
      (campaign?.auto_grant_rewards !== false),
    coupon_code_prefix:
      str(d.coupon_code_prefix) || campaign?.coupon_code_prefix || "REF",
  };
}

export async function getCampaign(
  campaignId: string
): Promise<ReferEarnCampaign | null> {
  if (!campaignId) return null;
  const snap = await db.collection("refer_earn_campaigns").doc(campaignId).get();
  if (!snap.exists) return null;
  return parseCampaign(snap.id, snap.data() ?? {});
}

export async function getActiveCampaign(): Promise<ReferEarnCampaign | null> {
  const settings = await getReferEarnSettings();
  if (!settings.enabled || !settings.active_campaign_id) return null;
  const campaign = await getCampaign(settings.active_campaign_id);
  if (!campaign || campaign.status !== "active") return null;
  return campaign;
}

function parseCampaign(
  id: string,
  data: admin.firestore.DocumentData
): ReferEarnCampaign {
  const stats = (data.stats as Record<string, unknown>) ?? {};
  return {
    id,
    name: str(data.name) || "Referral Campaign",
    coupon_code_prefix: str(data.coupon_code_prefix) || "REF",
    referrer_reward_amount: num(data.referrer_reward_amount, 50),
    new_user_reward_amount: num(data.new_user_reward_amount, 50),
    minimum_order_value: num(data.minimum_order_value, 299),
    max_referrals_per_user: Math.max(1, num(data.max_referrals_per_user, 10)),
    referral_validity_days: Math.max(1, num(data.referral_validity_days, 30)),
    campaign_validity_days: Math.max(
      1,
      num(data.campaign_validity_days, 365)
    ),
    status: (str(data.status) === "paused" ? "paused" : "active") as CampaignStatus,
    auto_grant_rewards: data.auto_grant_rewards !== false,
    stats: {
      invites_sent: num(stats.invites_sent),
      successful_referrals: num(stats.successful_referrals),
      pending_referrals: num(stats.pending_referrals),
      rewarded_referrals: num(stats.rewarded_referrals),
      total_discount_given: num(stats.total_discount_given),
      new_users_acquired: num(stats.new_users_acquired),
    },
  };
}

async function logFraud(
  type: string,
  details: Record<string, unknown>
): Promise<void> {
  await db.collection("refer_earn_fraud_logs").add({
    type,
    details,
    created_at: FieldValue.serverTimestamp(),
  });
}

export async function ensureUserReferralCode(
  userId: string,
  name?: string
): Promise<string> {
  const userRef = db.collection("customers").doc(userId);
  const userSnap = await userRef.get();
  const existing = str(userSnap.data()?.referral_code);
  if (existing && existing !== userId) {
    return existing.toUpperCase();
  }

  const displayName = str(name) || str(userSnap.data()?.name) || "USER";
  const prefix = namePrefix(displayName);

  for (let attempt = 0; attempt < 12; attempt++) {
    const code = `${prefix}${randomSuffix(attempt < 4 ? 3 : 4)}`;
    const codeRef = db.collection("referral_codes").doc(code);
    const codeSnap = await codeRef.get();
    if (codeSnap.exists && str(codeSnap.data()?.user_id) !== userId) {
      continue;
    }
    await db.runTransaction(async (tx) => {
      const again = await tx.get(codeRef);
      if (again.exists && str(again.data()?.user_id) !== userId) {
        throw new Error("CODE_TAKEN");
      }
      tx.set(
        codeRef,
        { user_id: userId, created_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
      tx.set(
        userRef,
        {
          referral_code: code,
          updated_at: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      tx.set(
        db.collection("users").doc(userId),
        { referral_code: code, updated_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
    });
    return code;
  }

  const fallback = `QG${userId.slice(-6).toUpperCase()}`;
  await userRef.set({ referral_code: fallback }, { merge: true });
  await db.collection("referral_codes").doc(fallback).set({
    user_id: userId,
    created_at: FieldValue.serverTimestamp(),
  });
  return fallback;
}

async function resolveReferrerFromCode(
  code: string
): Promise<{ userId: string; code: string } | null> {
  const normalized = normalizeCode(code);
  if (!normalized) return null;

  const codeSnap = await db.collection("referral_codes").doc(normalized).get();
  if (codeSnap.exists) {
    const userId = str(codeSnap.data()?.user_id);
    if (userId) return { userId, code: normalized };
  }

  const byField = await db
    .collection("customers")
    .where("referral_code", "==", normalized)
    .limit(1)
    .get();
  if (!byField.empty) {
    return { userId: byField.docs[0].id, code: normalized };
  }

  if (normalized.length >= 20) {
    const userSnap = await db.collection("customers").doc(normalized).get();
    if (userSnap.exists) {
      return { userId: normalized, code: normalized };
    }
  }

  return null;
}

async function countReferrerReferrals(referrerId: string): Promise<number> {
  const snap = await db
    .collection("referrals")
    .where("referrer_id", "==", referrerId)
    .where("disabled", "==", false)
    .get();
  return snap.docs.filter((d) => {
    const s = str(d.data().status);
    return s !== "rejected";
  }).length;
}

export interface ApplyReferralResult {
  ok: boolean;
  message: string;
  referralId?: string;
}

export async function applyReferralCode(
  referredUserId: string,
  rawCode: string
): Promise<ApplyReferralResult> {
  const settings = await getReferEarnSettings();
  if (!settings.enabled) {
    return { ok: false, message: "Refer & Earn is currently unavailable." };
  }

  const campaign = await getActiveCampaign();
  if (!campaign) {
    return { ok: false, message: "No active referral campaign." };
  }

  const code = normalizeCode(rawCode);
  if (!code) {
    return { ok: false, message: "Enter a valid referral code." };
  }

  const referrer = await resolveReferrerFromCode(code);
  if (!referrer) {
    return { ok: false, message: "Referral code does not exist." };
  }

  if (referrer.userId === referredUserId) {
    await logFraud("self_referral", { referredUserId, code });
    return { ok: false, message: "You cannot use your own referral code." };
  }

  const referredRef = db.collection("customers").doc(referredUserId);
  const referredSnap = await referredRef.get();
  const referredData = referredSnap.data() ?? {};

  if (str(referredData.referral_id)) {
    return { ok: false, message: "A referral is already linked to this account." };
  }
  if (str(referredData.referred_by)) {
    return { ok: false, message: "This account was already referred." };
  }

  const existingReferral = await db
    .collection("referrals")
    .where("referred_user_id", "==", referredUserId)
    .limit(1)
    .get();
  if (!existingReferral.empty) {
    return { ok: false, message: "Referral already registered for this user." };
  }

  const referrerSnap = await db
    .collection("customers")
    .doc(referrer.userId)
    .get();
  const referrerData = referrerSnap.data() ?? {};

  const referredPhone = normalizePhone(
    str(referredData.phone ?? referredData.mobile)
  );
  const referrerPhone = normalizePhone(
    str(referrerData.phone ?? referrerData.mobile)
  );
  if (referredPhone && referrerPhone && referredPhone === referrerPhone) {
    await logFraud("same_phone", {
      referredUserId,
      referrerId: referrer.userId,
      phone: referredPhone,
    });
    return { ok: false, message: "Referral could not be applied." };
  }

  const referredEmail = str(referredData.email).toLowerCase();
  const referrerEmail = str(referrerData.email).toLowerCase();
  if (
    referredEmail &&
    referrerEmail &&
    referredEmail === referrerEmail
  ) {
    await logFraud("same_email", {
      referredUserId,
      referrerId: referrer.userId,
      email: referredEmail,
    });
    return { ok: false, message: "Referral could not be applied." };
  }

  const referralCount = await countReferrerReferrals(referrer.userId);
  if (referralCount >= campaign.max_referrals_per_user) {
    return {
      ok: false,
      message: "This referrer has reached the maximum referral limit.",
    };
  }

  const referrerCode =
    str(referrerData.referral_code) || (await ensureUserReferralCode(
      referrer.userId,
      str(referrerData.name)
    ));

  const referralRef = db.collection("referrals").doc();
  const now = FieldValue.serverTimestamp();

  await db.runTransaction(async (tx) => {
    tx.set(referralRef, {
      campaign_id: campaign.id,
      referrer_id: referrer.userId,
      referrer_name: str(referrerData.name) || "User",
      referrer_phone: str(referrerData.phone ?? referrerData.mobile),
      referrer_email: str(referrerData.email),
      referrer_code: referrerCode,
      referred_user_id: referredUserId,
      referred_user_name: str(referredData.name) || "User",
      referred_user_phone: str(referredData.phone ?? referredData.mobile),
      referred_user_email: str(referredData.email),
      referral_date: now,
      signup_date: now,
      status: "first_order_pending",
      reward_status: "none",
      disabled: false,
      fraud_flags: [],
      created_at: now,
      updated_at: now,
    });

    tx.set(
      referredRef,
      {
        referred_by: referrer.userId,
        referral_id: referralRef.id,
        referral_code_used: referrerCode,
        updated_at: now,
      },
      { merge: true }
    );

    tx.set(
      db.collection("refer_earn_campaigns").doc(campaign.id),
      {
        "stats.invites_sent": FieldValue.increment(1),
        "stats.pending_referrals": FieldValue.increment(1),
        "stats.new_users_acquired": FieldValue.increment(1),
        updated_at: now,
      },
      { merge: true }
    );

    tx.set(
      db.collection("customers").doc(referrer.userId),
      { referral_count: FieldValue.increment(1) },
      { merge: true }
    );
  });

  await notifyReferralEvent(referrer.userId, {
    title: "Referral joined! 🎉",
    body: "A friend signed up with your code. Reward unlocks after their first delivered order.",
    type: "referral_joined",
  });
  await notifyReferralEvent(referredUserId, {
    title: "Welcome referral offer",
    body: "Complete your first delivered order to unlock your welcome reward.",
    type: "referral_joined",
  });

  return {
    ok: true,
    message: "Referral code applied successfully.",
    referralId: referralRef.id,
  };
}

async function notifyReferralEvent(
  userId: string,
  payload: { title: string; body: string; type: string }
): Promise<void> {
  await notifyCustomer(userId, {
    title: payload.title,
    body: payload.body,
    type: payload.type,
  });
  await writeUserInbox(userId, {
    title: payload.title,
    body: payload.body,
    type: "offer",
    deepLink: "/refer",
  });
}

async function countDeliveredOrders(userId: string): Promise<number> {
  const snap = await db
    .collection("orders")
    .where("uuid", "==", userId)
    .limit(50)
    .get();
  return snap.docs.filter((d) => {
    const data = d.data();
    const status = str(data.status ?? data.order_status).toLowerCase();
    return status === "delivered";
  }).length;
}

function orderSubtotal(data: Record<string, unknown>): number {
  const bill = data.bill as Record<string, unknown> | undefined;
  if (bill && bill.subtotal != null) return num(bill.subtotal);
  if (bill && bill.total != null) return num(bill.total);
  const products = (data.products as unknown[]) || [];
  let sum = 0;
  for (const p of products) {
    const row = p as Record<string, unknown>;
    sum += num(row.price) * num(row.itemCount || row.quantity || 1);
  }
  return sum;
}

async function createReferralCoupon(params: {
  userId: string;
  amount: number;
  prefix: string;
  validityDays: number;
  referralId: string;
  role: "referrer" | "referred";
  minimumOrder: number;
}): Promise<{ couponId: string; code: string }> {
  const suffix = `${params.role.toUpperCase().slice(0, 3)}${randomSuffix(4)}`;
  const code = `${params.prefix}${suffix}`.toUpperCase().slice(0, 24);
  const now = new Date();
  const expiry = new Date(now);
  expiry.setDate(expiry.getDate() + params.validityDays);

  const docRef = await db.collection("coupons").add({
    code,
    title: params.role === "referrer" ? "Referral reward" : "Welcome referral reward",
    coupon_type: "flat_discount",
    flat_amount: params.amount,
    discount: 0,
    minimum_order_amount: params.minimumOrder,
    maximum_discount_amount: params.amount,
    usage_limit: 1,
    used_count: 0,
    per_user_limit: 1,
    first_order_only: params.role === "referred",
    free_delivery: false,
    is_active: true,
    isActive: true,
    description: `Refer & Earn ${params.role} reward`,
    source: "refer_earn",
    refer_earn_referral_id: params.referralId,
    assigned_user_id: params.userId,
    start_date: Timestamp.fromDate(now),
    expiry_date: Timestamp.fromDate(expiry),
    createdAt: FieldValue.serverTimestamp(),
    analytics_total_usage: 0,
    analytics_failed_attempts: 0,
    analytics_revenue: 0,
    analytics_first_order_users: 0,
  });

  return { couponId: docRef.id, code };
}

export async function grantReferralRewards(
  referralId: string,
  options?: { adminUid?: string; force?: boolean }
): Promise<{ ok: boolean; message: string }> {
  const referralRef = db.collection("referrals").doc(referralId);
  const referralSnap = await referralRef.get();
  if (!referralSnap.exists) {
    return { ok: false, message: "Referral not found." };
  }

  const data = referralSnap.data() ?? {};
  if (data.disabled === true) {
    return { ok: false, message: "Referral is disabled." };
  }

  const status = str(data.status) as ReferralStatus;
  if (status === "reward_granted") {
    return { ok: false, message: "Rewards already granted." };
  }
  if (status === "rejected" && !options?.force) {
    return { ok: false, message: "Referral was rejected." };
  }

  const campaign = await getCampaign(str(data.campaign_id));
  if (!campaign) {
    return { ok: false, message: "Campaign not found." };
  }

  const referrerId = str(data.referrer_id);
  const referredId = str(data.referred_user_id);

  const referrerCoupon = await createReferralCoupon({
    userId: referrerId,
    amount: campaign.referrer_reward_amount,
    prefix: campaign.coupon_code_prefix,
    validityDays: campaign.referral_validity_days,
    referralId,
    role: "referrer",
    minimumOrder: campaign.minimum_order_value,
  });

  const referredCoupon = await createReferralCoupon({
    userId: referredId,
    amount: campaign.new_user_reward_amount,
    prefix: campaign.coupon_code_prefix,
    validityDays: campaign.referral_validity_days,
    referralId,
    role: "referred",
    minimumOrder: 0,
  });

  const totalDiscount =
    campaign.referrer_reward_amount + campaign.new_user_reward_amount;
  const now = FieldValue.serverTimestamp();

  await referralRef.update({
    status: "reward_granted",
    reward_status: "granted",
    referrer_coupon_id: referrerCoupon.couponId,
    referred_coupon_id: referredCoupon.couponId,
    referrer_coupon_code: referrerCoupon.code,
    referred_coupon_code: referredCoupon.code,
    rewarded_at: now,
    rewarded_by: options?.adminUid ?? "system",
    updated_at: now,
  });

  await db.collection("refer_earn_campaigns").doc(campaign.id).set(
    {
      "stats.rewarded_referrals": FieldValue.increment(1),
      "stats.successful_referrals": FieldValue.increment(1),
      "stats.pending_referrals": FieldValue.increment(-1),
      "stats.total_discount_given": FieldValue.increment(totalDiscount),
      updated_at: now,
    },
    { merge: true }
  );

  await db.collection("customers").doc(referrerId).set(
    {
      "wallet.referral_earnings": FieldValue.increment(
        campaign.referrer_reward_amount
      ),
      referral_earnings: FieldValue.increment(campaign.referrer_reward_amount),
    },
    { merge: true }
  );

  await notifyReferralEvent(referrerId, {
    title: "Coupon earned! 🎁",
    body: `You earned ₹${campaign.referrer_reward_amount} — use code ${referrerCoupon.code}.`,
    type: "referral_coupon_earned",
  });
  await notifyReferralEvent(referredId, {
    title: "Welcome coupon unlocked!",
    body: `Use code ${referredCoupon.code} on your next order.`,
    type: "referral_coupon_earned",
  });
  await notifyReferralEvent(referrerId, {
    title: "Reward granted",
    body: "Your referral reward has been credited successfully.",
    type: "referral_reward_granted",
  });

  return { ok: true, message: "Rewards granted successfully." };
}

export async function rejectReferral(
  referralId: string,
  reason: string,
  adminUid?: string
): Promise<{ ok: boolean; message: string }> {
  const referralRef = db.collection("referrals").doc(referralId);
  const snap = await referralRef.get();
  if (!snap.exists) return { ok: false, message: "Referral not found." };

  const data = snap.data() ?? {};
  if (str(data.status) === "reward_granted") {
    return { ok: false, message: "Cannot reject after rewards granted." };
  }

  await referralRef.update({
    status: "rejected",
    reward_status: "rejected",
    rejection_reason: reason,
    rejected_by: adminUid ?? "admin",
    rejected_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  const referredId = str(data.referred_user_id);
  if (referredId) {
    await notifyReferralEvent(referredId, {
      title: "Referral update",
      body: "Your referral could not be approved. Contact support if needed.",
      type: "referral_rejected",
    });
  }

  return { ok: true, message: "Referral rejected." };
}

export async function processReferralOnOrderDelivered(
  orderId: string,
  orderData: Record<string, unknown>
): Promise<void> {
  const settings = await getReferEarnSettings();
  if (!settings.enabled) return;

  const userId = str(orderData.uuid ?? orderData.userId);
  if (!userId) return;

  const referralSnap = await db
    .collection("referrals")
    .where("referred_user_id", "==", userId)
    .where("disabled", "==", false)
    .limit(1)
    .get();

  if (referralSnap.empty) return;

  const referralDoc = referralSnap.docs[0];
  const referral = referralDoc.data();
  const status = str(referral.status);

  if (status === "reward_granted" || status === "rejected") return;

  const deliveredCount = await countDeliveredOrders(userId);
  if (deliveredCount !== 1) return;

  const campaign = await getCampaign(str(referral.campaign_id));
  if (!campaign) return;

  const amount = orderSubtotal(orderData);
  const now = FieldValue.serverTimestamp();

  await referralDoc.ref.update({
    first_order_id: orderId,
    first_order_date: now,
    first_order_amount: amount,
    status: "reward_eligible",
    reward_status: "pending",
    updated_at: now,
  });

  await notifyReferralEvent(userId, {
    title: "First order completed!",
    body: "Your welcome referral reward is being processed.",
    type: "referral_first_order_completed",
  });

  const referrerId = str(referral.referrer_id);
  if (referrerId) {
    await notifyReferralEvent(referrerId, {
      title: "First order completed! 🛒",
      body: "Your friend placed their first order. Your reward is on the way.",
      type: "referral_first_order_completed",
    });
  }

  if (amount < campaign.minimum_order_value) {
    await referralDoc.ref.update({
      fraud_flags: FieldValue.arrayUnion([
        `order_below_minimum:${amount}<${campaign.minimum_order_value}`,
      ]),
      updated_at: FieldValue.serverTimestamp(),
    });
    return;
  }

  if (campaign.auto_grant_rewards) {
    await grantReferralRewards(referralDoc.id);
  }
}

export async function getUserReferEarnStats(userId: string): Promise<Record<string, unknown>> {
  const settings = await getReferEarnSettings();
  const campaign = settings.enabled ? await getActiveCampaign() : null;
  const code = await ensureUserReferralCode(userId);
  const playStoreUrl = str(settings.play_store_url);
  const canShare = playStoreUrl.length > 0;

  const referrerReward =
    campaign?.referrer_reward_amount ?? settings.referrer_reward_amount;
  const friendReward =
    campaign?.new_user_reward_amount ?? settings.new_user_reward_amount;
  const minOrder =
    campaign?.minimum_order_value ?? settings.minimum_order_value;

  const asReferrer = await db
    .collection("referrals")
    .where("referrer_id", "==", userId)
    .limit(50)
    .get();

  let invites = 0;
  let joined = 0;
  let ordered = 0;
  let pending = 0;
  let successful = 0;
  let rewards = 0;
  const history: ReferralHistoryItem[] = [];

  const sortedDocs = [...asReferrer.docs].sort((a, b) => {
    const ta = a.data().created_at as { toMillis?: () => number } | undefined;
    const tb = b.data().created_at as { toMillis?: () => number } | undefined;
    return (tb?.toMillis?.() ?? 0) - (ta?.toMillis?.() ?? 0);
  });

  for (const doc of sortedDocs) {
    const data = doc.data();
    const s = str(data.status) as ReferralStatus;
    if (s === "rejected" || data.disabled === true) continue;

    invites++;
    joined++;

    if (s === "reward_eligible" || s === "reward_granted") {
      ordered++;
    }
    if (s === "first_order_pending" || s === "pending") {
      pending++;
    }
    if (s === "reward_granted") {
      successful++;
      rewards += referrerReward;
    }

    const signupTs = data.signup_date ?? data.referral_date ?? data.created_at;
    let joinedDate: string | null = null;
    if (signupTs && typeof (signupTs as { toDate?: () => Date }).toDate === "function") {
      joinedDate = (signupTs as { toDate: () => Date }).toDate().toISOString();
    }

    history.push({
      id: doc.id,
      friendName: str(data.referred_user_name) || "Friend",
      joinedDate,
      status: s,
      statusLabel: referralStatusLabel(s),
      rewardStatus: (str(data.reward_status) || "none") as RewardStatus,
    });
  }

  const shareMessage = canShare
    ? buildReferralShareMessage(settings, campaign, code)
    : "";

  return {
    referralCode: code,
    enabled: settings.enabled && campaign != null,
    canShare,
    playStoreUrl,
    shareMessage,
    referrerReward,
    friendReward,
    minOrderValue: minOrder,
    campaignName: campaign?.name ?? "",
    invitesSent: invites,
    joinedCount: joined,
    orderedCount: ordered,
    pendingReferrals: pending,
    successfulReferrals: successful,
    totalRewardsEarned: rewards,
    totalReferrals: invites,
    newUserReward: friendReward,
    history,
  };
}

export async function resendReferralCoupons(
  referralId: string
): Promise<{ ok: boolean; message: string }> {
  const snap = await db.collection("referrals").doc(referralId).get();
  if (!snap.exists) return { ok: false, message: "Referral not found." };
  const data = snap.data() ?? {};
  if (str(data.status) !== "reward_granted") {
    return { ok: false, message: "Rewards not granted yet." };
  }

  const referrerId = str(data.referrer_id);
  const referredId = str(data.referred_user_id);
  const refCode = str(data.referrer_coupon_code);
  const newCode = str(data.referred_coupon_code);

  if (referrerId && refCode) {
    await notifyReferralEvent(referrerId, {
      title: "Your referral coupon",
      body: `Coupon code: ${refCode}`,
      type: "referral_coupon_resent",
    });
  }
  if (referredId && newCode) {
    await notifyReferralEvent(referredId, {
      title: "Your welcome coupon",
      body: `Coupon code: ${newCode}`,
      type: "referral_coupon_resent",
    });
  }

  return { ok: true, message: "Coupon codes resent." };
}

export async function disableReferral(
  referralId: string
): Promise<{ ok: boolean; message: string }> {
  const ref = db.collection("referrals").doc(referralId);
  const snap = await ref.get();
  if (!snap.exists) return { ok: false, message: "Referral not found." };
  await ref.update({
    disabled: true,
    updated_at: FieldValue.serverTimestamp(),
  });
  return { ok: true, message: "Referral disabled." };
}
