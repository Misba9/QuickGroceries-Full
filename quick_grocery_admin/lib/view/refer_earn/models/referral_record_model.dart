import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralRecordModel {
  ReferralRecordModel({
    required this.id,
    required this.campaignId,
    required this.referrerId,
    required this.referrerName,
    required this.referrerPhone,
    required this.referrerCode,
    required this.referredUserId,
    required this.referredUserName,
    required this.referredUserPhone,
    required this.status,
    required this.rewardStatus,
    required this.disabled,
    this.referrerEmail = '',
    this.referredUserEmail = '',
    this.referralDate,
    this.signupDate,
    this.firstOrderAmount,
    this.referrerCouponCode,
    this.referredCouponCode,
    this.fraudFlags = const [],
  });

  final String id;
  final String campaignId;
  final String referrerId;
  final String referrerName;
  final String referrerPhone;
  final String referrerEmail;
  final String referrerCode;
  final String referredUserId;
  final String referredUserName;
  final String referredUserPhone;
  final String referredUserEmail;
  final DateTime? referralDate;
  final DateTime? signupDate;
  final double? firstOrderAmount;
  final String status;
  final String rewardStatus;
  final String? referrerCouponCode;
  final String? referredCouponCode;
  final bool disabled;
  final List<String> fraudFlags;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'first_order_pending':
        return 'First Order Pending';
      case 'reward_eligible':
        return 'Reward Eligible';
      case 'reward_granted':
        return 'Reward Granted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  factory ReferralRecordModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ReferralRecordModel.fromMap(doc.data() ?? {}, doc.id);
  }

  factory ReferralRecordModel.fromMap(Map<String, dynamic> m, String id) {
    DateTime? ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    List<String> flags = [];
    final raw = m['fraud_flags'];
    if (raw is List) {
      flags = raw.map((e) => e.toString()).toList();
    }

    return ReferralRecordModel(
      id: id,
      campaignId: (m['campaign_id'] ?? '').toString(),
      referrerId: (m['referrer_id'] ?? '').toString(),
      referrerName: (m['referrer_name'] ?? '—').toString(),
      referrerPhone: (m['referrer_phone'] ?? '—').toString(),
      referrerEmail: (m['referrer_email'] ?? '').toString(),
      referrerCode: (m['referrer_code'] ?? '—').toString(),
      referredUserId: (m['referred_user_id'] ?? '').toString(),
      referredUserName: (m['referred_user_name'] ?? '—').toString(),
      referredUserPhone: (m['referred_user_phone'] ?? '—').toString(),
      referredUserEmail: (m['referred_user_email'] ?? '').toString(),
      referralDate: ts(m['referral_date']),
      signupDate: ts(m['signup_date']),
      firstOrderAmount: (m['first_order_amount'] as num?)?.toDouble(),
      status: (m['status'] ?? 'pending').toString(),
      rewardStatus: (m['reward_status'] ?? 'none').toString(),
      referrerCouponCode: m['referrer_coupon_code']?.toString(),
      referredCouponCode: m['referred_coupon_code']?.toString(),
      disabled: m['disabled'] == true,
      fraudFlags: flags,
    );
  }
}

class TopReferrerModel {
  const TopReferrerModel({
    required this.referrerId,
    required this.referrerName,
    required this.referrerPhone,
    required this.referrerCode,
    required this.count,
    required this.rewarded,
  });

  final String referrerId;
  final String referrerName;
  final String referrerPhone;
  final String referrerCode;
  final int count;
  final int rewarded;
}
