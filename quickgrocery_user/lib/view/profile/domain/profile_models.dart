import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/core/user/cod_eligibility.dart';
import 'package:quickgrocery/models/customer_model.dart';

/// Extended profile data merged from `customers/{uid}`.
class ProfileData {
  const ProfileData({
    required this.customer,
    required this.walletBalance,
    required this.rewardPoints,
    required this.cashbackEarned,
    required this.referralEarnings,
    required this.isPremiumMember,
    required this.referralCode,
    required this.gender,
    this.codEligibility = CodEligibility.allowed,
  });

  final CustomerModel customer;
  final double walletBalance;
  final int rewardPoints;
  final double cashbackEarned;
  final double referralEarnings;
  final bool isPremiumMember;
  final String referralCode;
  final String gender;
  final CodEligibility codEligibility;

  factory ProfileData.fromFirestore(Map<String, dynamic> data, String uid) {
    final wallet = data['wallet'] is Map
        ? Map<String, dynamic>.from(data['wallet'] as Map)
        : const <String, dynamic>{};

    final mapped = Map<String, dynamic>.from(data);
    // Normalize Timestamps for CodEligibility parsing.
    for (final key in [
      'codRestrictionEnd',
      'codRestrictionStart',
      'codUpdatedAt',
    ]) {
      final v = mapped[key];
      if (v is Timestamp) mapped[key] = v.toDate().toIso8601String();
    }

    return ProfileData(
      customer: CustomerModel.fromFirestore(data, uid),
      walletBalance: (wallet['balance'] as num?)?.toDouble() ??
          (data['wallet_balance'] as num?)?.toDouble() ??
          0,
      rewardPoints: (wallet['reward_points'] as num?)?.toInt() ??
          (data['reward_points'] as num?)?.toInt() ??
          0,
      cashbackEarned: (wallet['cashback_earned'] as num?)?.toDouble() ??
          (data['cashback_earned'] as num?)?.toDouble() ??
          0,
      referralEarnings: (wallet['referral_earnings'] as num?)?.toDouble() ??
          (data['referral_earnings'] as num?)?.toDouble() ??
          0,
      isPremiumMember: data['is_premium'] == true ||
          data['membership'] == 'premium' ||
          data['isPremiumMember'] == true,
      referralCode: (data['referral_code'] ?? data['uid'] ?? uid).toString(),
      gender: (data['gender'] ?? '').toString(),
      codEligibility: CodEligibility.fromMap(mapped),
    );
  }

  int get profileCompletionPercent {
    var score = 0;
    if (customer.name.trim().isNotEmpty) score += 25;
    if (customer.phoneNumber.trim().isNotEmpty) score += 25;
    if (customer.email.trim().isNotEmpty) score += 20;
    if (customer.image.trim().isNotEmpty) score += 20;
    if (gender.trim().isNotEmpty) score += 10;
    return score.clamp(0, 100);
  }
}

class OrderCounts {
  const OrderCounts({
    required this.pending,
    required this.delivered,
    required this.cancelled,
    required this.returned,
  });

  final int pending;
  final int delivered;
  final int cancelled;
  final int returned;

  int get total => pending + delivered + cancelled + returned;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.orderUpdates = true,
    this.offersDiscounts = true,
    this.walletUpdates = true,
    this.productAlerts = true,
    this.promotionalMessages = false,
    this.deliveryNotifications = true,
  });

  final bool orderUpdates;
  final bool offersDiscounts;
  final bool walletUpdates;
  final bool productAlerts;
  final bool promotionalMessages;
  final bool deliveryNotifications;

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? offersDiscounts,
    bool? walletUpdates,
    bool? productAlerts,
    bool? promotionalMessages,
    bool? deliveryNotifications,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      offersDiscounts: offersDiscounts ?? this.offersDiscounts,
      walletUpdates: walletUpdates ?? this.walletUpdates,
      productAlerts: productAlerts ?? this.productAlerts,
      promotionalMessages: promotionalMessages ?? this.promotionalMessages,
      deliveryNotifications:
          deliveryNotifications ?? this.deliveryNotifications,
    );
  }

  Map<String, bool> toMap() => {
        'orderUpdates': orderUpdates,
        'offersDiscounts': offersDiscounts,
        'walletUpdates': walletUpdates,
        'productAlerts': productAlerts,
        'promotionalMessages': promotionalMessages,
        'deliveryNotifications': deliveryNotifications,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      orderUpdates: map['orderUpdates'] as bool? ?? true,
      offersDiscounts: map['offersDiscounts'] as bool? ?? true,
      walletUpdates: map['walletUpdates'] as bool? ?? true,
      productAlerts: map['productAlerts'] as bool? ?? true,
      promotionalMessages: map['promotionalMessages'] as bool? ?? false,
      deliveryNotifications: map['deliveryNotifications'] as bool? ?? true,
    );
  }
}
