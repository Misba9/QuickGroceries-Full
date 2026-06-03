export const REFERRAL_STATUSES = [
  "pending",
  "first_order_pending",
  "reward_eligible",
  "reward_granted",
  "rejected",
] as const;

export type ReferralStatus = (typeof REFERRAL_STATUSES)[number];

export const REWARD_STATUSES = [
  "none",
  "pending",
  "granted",
  "rejected",
] as const;

export type RewardStatus = (typeof REWARD_STATUSES)[number];

export const CAMPAIGN_STATUSES = ["active", "paused"] as const;

export type CampaignStatus = (typeof CAMPAIGN_STATUSES)[number];

export const DEFAULT_SHARE_MESSAGE_TEMPLATE = `Get groceries delivered in minutes with Quick Groceries.

Use my referral code {code} and get ₹{friend_reward} OFF on your first order.

Download App:
{play_store_url}`;

export interface ReferEarnSettings {
  enabled: boolean;
  active_campaign_id: string;
  play_store_url: string;
  share_message_template: string;
  referrer_reward_amount: number;
  new_user_reward_amount: number;
  minimum_order_value: number;
  coupon_expiry_days: number;
  max_referrals_per_user: number;
  auto_grant_rewards: boolean;
  coupon_code_prefix: string;
}

export interface ReferralHistoryItem {
  id: string;
  friendName: string;
  joinedDate: string | null;
  status: ReferralStatus;
  statusLabel: string;
  rewardStatus: RewardStatus;
}

export interface ReferEarnCampaign {
  id: string;
  name: string;
  coupon_code_prefix: string;
  referrer_reward_amount: number;
  new_user_reward_amount: number;
  minimum_order_value: number;
  max_referrals_per_user: number;
  referral_validity_days: number;
  campaign_validity_days: number;
  status: CampaignStatus;
  auto_grant_rewards: boolean;
  stats: {
    invites_sent: number;
    successful_referrals: number;
    pending_referrals: number;
    rewarded_referrals: number;
    total_discount_given: number;
    new_users_acquired: number;
  };
}

import type { Timestamp } from "firebase-admin/firestore";

export interface ReferralRecord {
  id: string;
  campaign_id: string;
  referrer_id: string;
  referrer_name: string;
  referrer_phone: string;
  referrer_email: string;
  referrer_code: string;
  referred_user_id: string;
  referred_user_name: string;
  referred_user_phone: string;
  referred_user_email: string;
  referral_date: Timestamp;
  signup_date?: Timestamp;
  first_order_id?: string;
  first_order_date?: Timestamp;
  first_order_amount?: number;
  status: ReferralStatus;
  reward_status: RewardStatus;
  referrer_coupon_id?: string;
  referred_coupon_id?: string;
  referrer_coupon_code?: string;
  referred_coupon_code?: string;
  disabled: boolean;
  fraud_flags: string[];
}
