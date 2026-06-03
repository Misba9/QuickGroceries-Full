class ReferEarnSettingsModel {
  const ReferEarnSettingsModel({
    required this.enabled,
    required this.activeCampaignId,
    required this.playStoreUrl,
    required this.shareMessageTemplate,
    required this.referrerRewardAmount,
    required this.newUserRewardAmount,
    required this.minimumOrderValue,
    required this.couponExpiryDays,
    required this.maxReferralsPerUser,
    required this.autoGrantRewards,
    required this.couponCodePrefix,
  });

  final bool enabled;
  final String activeCampaignId;
  final String playStoreUrl;
  final String shareMessageTemplate;
  final int referrerRewardAmount;
  final int newUserRewardAmount;
  final int minimumOrderValue;
  final int couponExpiryDays;
  final int maxReferralsPerUser;
  final bool autoGrantRewards;
  final String couponCodePrefix;

  static const defaultShareTemplate = '''Get groceries delivered in minutes with Quick Groceries.

Use my referral code {code} and get ₹{friend_reward} OFF on your first order.

Download App:
{play_store_url}''';

  factory ReferEarnSettingsModel.fromMap(Map<String, dynamic>? m) {
    if (m == null) return ReferEarnSettingsModel.defaults();
    return ReferEarnSettingsModel(
      enabled: m['enabled'] == true,
      activeCampaignId: (m['active_campaign_id'] ?? '').toString(),
      playStoreUrl: (m['play_store_url'] ?? '').toString(),
      shareMessageTemplate: (m['share_message_template'] ?? defaultShareTemplate)
          .toString(),
      referrerRewardAmount: (m['referrer_reward_amount'] as num?)?.toInt() ?? 50,
      newUserRewardAmount: (m['new_user_reward_amount'] as num?)?.toInt() ?? 50,
      minimumOrderValue: (m['minimum_order_value'] as num?)?.toInt() ?? 199,
      couponExpiryDays: (m['coupon_expiry_days'] as num?)?.toInt() ?? 30,
      maxReferralsPerUser: (m['max_referrals_per_user'] as num?)?.toInt() ?? 10,
      autoGrantRewards: m['auto_grant_rewards'] != false,
      couponCodePrefix: (m['coupon_code_prefix'] ?? 'REF').toString(),
    );
  }

  factory ReferEarnSettingsModel.defaults() => const ReferEarnSettingsModel(
        enabled: false,
        activeCampaignId: '',
        playStoreUrl: '',
        shareMessageTemplate: defaultShareTemplate,
        referrerRewardAmount: 50,
        newUserRewardAmount: 50,
        minimumOrderValue: 199,
        couponExpiryDays: 30,
        maxReferralsPerUser: 10,
        autoGrantRewards: true,
        couponCodePrefix: 'REF',
      );

  Map<String, dynamic> toFirestore() => {
        'enabled': enabled,
        if (activeCampaignId.isNotEmpty)
          'active_campaign_id': activeCampaignId,
        'play_store_url': playStoreUrl.trim(),
        'share_message_template': shareMessageTemplate,
        'referrer_reward_amount': referrerRewardAmount,
        'new_user_reward_amount': newUserRewardAmount,
        'minimum_order_value': minimumOrderValue,
        'coupon_expiry_days': couponExpiryDays,
        'max_referrals_per_user': maxReferralsPerUser,
        'auto_grant_rewards': autoGrantRewards,
        'coupon_code_prefix': couponCodePrefix.toUpperCase(),
      };
}
