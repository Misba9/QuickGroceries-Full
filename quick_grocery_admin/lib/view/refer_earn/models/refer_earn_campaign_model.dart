import 'package:cloud_firestore/cloud_firestore.dart';

class ReferEarnCampaignModel {
  ReferEarnCampaignModel({
    required this.id,
    required this.name,
    required this.couponCodePrefix,
    required this.referrerRewardAmount,
    required this.newUserRewardAmount,
    required this.minimumOrderValue,
    required this.maxReferralsPerUser,
    required this.referralValidityDays,
    required this.campaignValidityDays,
    required this.status,
    required this.autoGrantRewards,
    required this.stats,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String couponCodePrefix;
  final int referrerRewardAmount;
  final int newUserRewardAmount;
  final int minimumOrderValue;
  final int maxReferralsPerUser;
  final int referralValidityDays;
  final int campaignValidityDays;
  final String status;
  final bool autoGrantRewards;
  final ReferEarnCampaignStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';

  factory ReferEarnCampaignModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ReferEarnCampaignModel.fromMap(doc.data() ?? {}, doc.id);
  }

  factory ReferEarnCampaignModel.fromMap(Map<String, dynamic> m, String id) {
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    final statsMap = m['stats'] as Map<String, dynamic>? ?? {};
    return ReferEarnCampaignModel(
      id: id,
      name: (m['name'] ?? 'Campaign').toString(),
      couponCodePrefix: (m['coupon_code_prefix'] ?? 'REF').toString(),
      referrerRewardAmount:
          (m['referrer_reward_amount'] as num?)?.toInt() ?? 50,
      newUserRewardAmount: (m['new_user_reward_amount'] as num?)?.toInt() ?? 50,
      minimumOrderValue: (m['minimum_order_value'] as num?)?.toInt() ?? 299,
      maxReferralsPerUser: (m['max_referrals_per_user'] as num?)?.toInt() ?? 10,
      referralValidityDays: (m['referral_validity_days'] as num?)?.toInt() ?? 30,
      campaignValidityDays:
          (m['campaign_validity_days'] as num?)?.toInt() ?? 365,
      status: (m['status'] ?? 'active').toString(),
      autoGrantRewards: m['auto_grant_rewards'] != false,
      stats: ReferEarnCampaignStats.fromMap(statsMap),
      createdAt: ts(m['created_at'] ?? m['createdAt']),
      updatedAt: ts(m['updated_at'] ?? m['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'coupon_code_prefix': couponCodePrefix.toUpperCase(),
        'referrer_reward_amount': referrerRewardAmount,
        'new_user_reward_amount': newUserRewardAmount,
        'minimum_order_value': minimumOrderValue,
        'max_referrals_per_user': maxReferralsPerUser,
        'referral_validity_days': referralValidityDays,
        'campaign_validity_days': campaignValidityDays,
        'status': status,
        'auto_grant_rewards': autoGrantRewards,
        'stats': stats.toMap(),
      };

  ReferEarnCampaignModel copyWith({
    String? name,
    String? couponCodePrefix,
    int? referrerRewardAmount,
    int? newUserRewardAmount,
    int? minimumOrderValue,
    int? maxReferralsPerUser,
    int? referralValidityDays,
    int? campaignValidityDays,
    String? status,
    bool? autoGrantRewards,
  }) {
    return ReferEarnCampaignModel(
      id: id,
      name: name ?? this.name,
      couponCodePrefix: couponCodePrefix ?? this.couponCodePrefix,
      referrerRewardAmount: referrerRewardAmount ?? this.referrerRewardAmount,
      newUserRewardAmount: newUserRewardAmount ?? this.newUserRewardAmount,
      minimumOrderValue: minimumOrderValue ?? this.minimumOrderValue,
      maxReferralsPerUser: maxReferralsPerUser ?? this.maxReferralsPerUser,
      referralValidityDays: referralValidityDays ?? this.referralValidityDays,
      campaignValidityDays: campaignValidityDays ?? this.campaignValidityDays,
      status: status ?? this.status,
      autoGrantRewards: autoGrantRewards ?? this.autoGrantRewards,
      stats: stats,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ReferEarnCampaignStats {
  const ReferEarnCampaignStats({
    this.invitesSent = 0,
    this.successfulReferrals = 0,
    this.pendingReferrals = 0,
    this.rewardedReferrals = 0,
    this.totalDiscountGiven = 0,
    this.newUsersAcquired = 0,
  });

  final int invitesSent;
  final int successfulReferrals;
  final int pendingReferrals;
  final int rewardedReferrals;
  final double totalDiscountGiven;
  final int newUsersAcquired;

  factory ReferEarnCampaignStats.fromMap(Map<String, dynamic> m) {
    return ReferEarnCampaignStats(
      invitesSent: (m['invites_sent'] as num?)?.toInt() ?? 0,
      successfulReferrals: (m['successful_referrals'] as num?)?.toInt() ?? 0,
      pendingReferrals: (m['pending_referrals'] as num?)?.toInt() ?? 0,
      rewardedReferrals: (m['rewarded_referrals'] as num?)?.toInt() ?? 0,
      totalDiscountGiven: (m['total_discount_given'] as num?)?.toDouble() ?? 0,
      newUsersAcquired: (m['new_users_acquired'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'invites_sent': invitesSent,
        'successful_referrals': successfulReferrals,
        'pending_referrals': pendingReferrals,
        'rewarded_referrals': rewardedReferrals,
        'total_discount_given': totalDiscountGiven,
        'new_users_acquired': newUsersAcquired,
      };
}

