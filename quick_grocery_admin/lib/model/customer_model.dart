import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';

enum CustomerAccountStatus {
  active,
  blocked,
  suspended,
  inactive,
  deleted,
  fraudRisk,
}

enum CustomerLoyaltyTier { bronze, silver, gold, platinum }

enum CustomerRiskLevel { low, medium, high }

class CustomerModel {
  final String image;
  final String name;
  final String email;
  final String phoneNumber;
  final String id;
  final String firestoreDocId;
  final String createdDate;
  final String referId;
  final String city;
  final String state;
  final String deviceType;
  final String appVersion;
  final String lastActiveAt;
  final bool isBlocked;
  /// When false, checkout only allows online payment (COD hidden).
  final bool codEnabled;
  final CustomerAccountStatus status;
  final bool phoneVerified;
  final bool emailVerified;
  final bool kycVerified;
  final bool isOnline;
  final double walletBalance;
  final int rewardPoints;
  final int referralCount;
  final CustomerLoyaltyTier loyaltyTier;
  final String ipAddress;
  final String activeCartItems;
  final DateTime? createdAtTs;
  final DateTime? lastActiveTs;

  CustomerModel({
    required this.image,
    required this.name,
    required this.email,
    required this.id,
    this.firestoreDocId = '',
    required this.phoneNumber,
    required this.isBlocked,
    this.codEnabled = true,
    required this.createdDate,
    this.referId = '',
    this.city = '',
    this.state = '',
    this.deviceType = '',
    this.appVersion = '',
    this.lastActiveAt = '',
    this.status = CustomerAccountStatus.active,
    this.phoneVerified = false,
    this.emailVerified = false,
    this.kycVerified = false,
    this.isOnline = false,
    this.walletBalance = 0,
    this.rewardPoints = 0,
    this.referralCount = 0,
    this.loyaltyTier = CustomerLoyaltyTier.bronze,
    this.ipAddress = '',
    this.activeCartItems = '',
    this.createdAtTs,
    this.lastActiveTs,
  });

  String get docId => firestoreDocId.isNotEmpty ? firestoreDocId : id;

  factory CustomerModel.fromFirestore(Map<String, dynamic> data, String docId) {
    final createdRaw = data['createdAt'] ?? data['created_date'];
    DateTime? createdTs;
    String createdStr = '';
    if (createdRaw is Timestamp) {
      createdTs = createdRaw.toDate();
      createdStr = createdTs.toIso8601String();
    } else if (createdRaw is String) {
      createdStr = createdRaw;
      createdTs = DateTime.tryParse(createdRaw);
    }

    final lastRaw = data['last_active_at'] ??
        data['lastActiveAt'] ??
        data['last_seen'] ??
        data['fcmUpdatedAt'];
    DateTime? lastTs;
    String lastStr = '';
    if (lastRaw is Timestamp) {
      lastTs = lastRaw.toDate();
      lastStr = lastTs.toIso8601String();
    } else if (lastRaw is String) {
      lastStr = lastRaw;
      lastTs = DateTime.tryParse(lastRaw);
    }

    final blocked = data['is_blocked'] == true;
    final status = _parseStatus(data, blocked);
    final wallet = (data['wallet_balance'] as num?)?.toDouble() ??
        (data['walletBalance'] as num?)?.toDouble() ??
        0;

    return CustomerModel(
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      phoneNumber: (data['phone'] ?? '').toString(),
      image: (data['profile_image'] ?? '').toString(),
      id: (data['uid'] ?? docId).toString(),
      firestoreDocId: docId,
      isBlocked: blocked,
      codEnabled: !CodPaymentRestriction.fromMap(data).isRestrictedNow,
      createdDate: createdStr,
      referId: (data['referred_by'] ?? data['referId'] ?? '').toString(),
      city: (data['city'] ?? data['location_city'] ?? '').toString(),
      state: (data['state'] ?? data['location_state'] ?? '').toString(),
      deviceType: (data['fcmPlatform'] ??
              data['device_type'] ??
              data['platform'] ??
              '')
          .toString(),
      appVersion: (data['app_version'] ??
              data['appVersion'] ??
              data['version'] ??
              '')
          .toString(),
      lastActiveAt: lastStr,
      status: status,
      phoneVerified: data['phone_verified'] == true,
      emailVerified: data['email_verified'] == true,
      kycVerified: data['kyc_verified'] == true,
      isOnline: data['is_online'] == true,
      walletBalance: wallet,
      rewardPoints: (data['reward_points'] as num?)?.toInt() ?? 0,
      referralCount: (data['referral_count'] as num?)?.toInt() ?? 0,
      loyaltyTier: _parseTier(data['loyalty_tier']),
      ipAddress: (data['last_ip'] ?? data['ip_address'] ?? '').toString(),
      activeCartItems: (data['active_cart_count'] ?? '').toString(),
      createdAtTs: createdTs,
      lastActiveTs: lastTs,
    );
  }

  Map<String, dynamic> toFirestoreUpdate() => {
        'name': name,
        'email': email,
        'phone': phoneNumber,
        'is_blocked': isBlocked,
        'account_status': status.name,
      };

  static CustomerAccountStatus _parseStatus(
    Map<String, dynamic> data,
    bool blocked,
  ) {
    final raw = (data['account_status'] ?? data['status'] ?? '')
        .toString()
        .toLowerCase();
    if (blocked || raw == 'blocked') return CustomerAccountStatus.blocked;
    if (raw.contains('suspend')) return CustomerAccountStatus.suspended;
    if (raw.contains('inactive')) return CustomerAccountStatus.inactive;
    if (raw.contains('delete')) return CustomerAccountStatus.deleted;
    if (raw.contains('fraud')) return CustomerAccountStatus.fraudRisk;
    return CustomerAccountStatus.active;
  }

  static CustomerLoyaltyTier _parseTier(dynamic v) {
    final s = v?.toString().toLowerCase() ?? '';
    if (s.contains('platinum')) return CustomerLoyaltyTier.platinum;
    if (s.contains('gold')) return CustomerLoyaltyTier.gold;
    if (s.contains('silver')) return CustomerLoyaltyTier.silver;
    return CustomerLoyaltyTier.bronze;
  }

  CustomerModel copyWith({
    bool? isBlocked,
    bool? codEnabled,
    CustomerAccountStatus? status,
    double? walletBalance,
    int? rewardPoints,
    int? referralCount,
    bool? isOnline,
    CustomerLoyaltyTier? loyaltyTier,
  }) {
    return CustomerModel(
      image: image,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      id: id,
      firestoreDocId: firestoreDocId,
      isBlocked: isBlocked ?? this.isBlocked,
      codEnabled: codEnabled ?? this.codEnabled,
      createdDate: createdDate,
      referId: referId,
      city: city,
      state: state,
      deviceType: deviceType,
      appVersion: appVersion,
      lastActiveAt: lastActiveAt,
      status: status ?? this.status,
      phoneVerified: phoneVerified,
      emailVerified: emailVerified,
      kycVerified: kycVerified,
      walletBalance: walletBalance ?? this.walletBalance,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      referralCount: referralCount ?? this.referralCount,
      isOnline: isOnline ?? this.isOnline,
      loyaltyTier: loyaltyTier ?? this.loyaltyTier,
      ipAddress: ipAddress,
      activeCartItems: activeCartItems,
      createdAtTs: createdAtTs,
      lastActiveTs: lastActiveTs,
    );
  }
}
