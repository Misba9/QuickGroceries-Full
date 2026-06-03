import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_campaign_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/refer_earn_settings_model.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/referral_record_model.dart';

class ReferEarnAdminService {
  ReferEarnAdminService({FirebaseFirestore? firestore, FirebaseFunctions? fn})
      : _db = firestore ?? FirebaseFirestore.instance,
        _fn = fn ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: 'us-central1',
            );

  final FirebaseFirestore _db;
  final FirebaseFunctions _fn;

  static const settingsPath = 'refer_earn_settings/global';

  Stream<ReferEarnSettingsModel> watchSettings() {
    return _db.doc(settingsPath).snapshots().map((s) {
      return ReferEarnSettingsModel.fromMap(s.data());
    });
  }

  Future<void> setEnabled(bool enabled) async {
    await _db.doc(settingsPath).set(
      {'enabled': enabled, 'updated_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> setActiveCampaign(String campaignId) async {
    await _db.doc(settingsPath).set(
      {
        'active_campaign_id': campaignId,
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> saveSettings(ReferEarnSettingsModel settings) async {
    await _db.doc(settingsPath).set(
      {
        ...settings.toFirestore(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (settings.activeCampaignId.isNotEmpty) {
      await _db
          .collection('refer_earn_campaigns')
          .doc(settings.activeCampaignId)
          .set(
        {
          'referrer_reward_amount': settings.referrerRewardAmount,
          'new_user_reward_amount': settings.newUserRewardAmount,
          'minimum_order_value': settings.minimumOrderValue,
          'referral_validity_days': settings.couponExpiryDays,
          'max_referrals_per_user': settings.maxReferralsPerUser,
          'auto_grant_rewards': settings.autoGrantRewards,
          'coupon_code_prefix': settings.couponCodePrefix.toUpperCase(),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  Stream<List<ReferEarnCampaignModel>> watchCampaigns() {
    return _db
        .collection('refer_earn_campaigns')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReferEarnCampaignModel.fromDoc).toList());
  }

  Future<String> createCampaign(ReferEarnCampaignModel model) async {
    final ref = await _db.collection('refer_earn_campaigns').add({
      ...model.toFirestore(),
      'status': model.status,
      'stats': ReferEarnCampaignStats().toMap(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateCampaign(ReferEarnCampaignModel model) async {
    await _db.collection('refer_earn_campaigns').doc(model.id).update({
      ...model.toFirestore(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCampaignStatus(String id, String status) async {
    await _db.collection('refer_earn_campaigns').doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ReferralRecordModel>> watchReferrals({
    String statusFilter = 'all',
    String search = '',
  }) {
    return _db
        .collection('referrals')
        .orderBy('created_at', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) {
      var list = snap.docs.map(ReferralRecordModel.fromDoc).toList();
      if (statusFilter != 'all') {
        list = list.where((r) => r.status == statusFilter).toList();
      }
      final q = search.trim().toLowerCase();
      if (q.isEmpty) return list;
      return list.where((r) {
        return r.referrerName.toLowerCase().contains(q) ||
            r.referrerPhone.contains(q) ||
            r.referrerCode.toLowerCase().contains(q) ||
            r.referredUserName.toLowerCase().contains(q) ||
            r.referredUserPhone.contains(q) ||
            r.id.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<List<TopReferrerModel>> fetchTopReferrers({int limit = 10}) async {
    final snap = await _db.collection('referrals').limit(1000).get();
    final map = <String, _ReferrerAgg>{};

    for (final doc in snap.docs) {
      final m = doc.data();
      final id = (m['referrer_id'] ?? '').toString();
      if (id.isEmpty) continue;
      final agg = map.putIfAbsent(
        id,
        () => _ReferrerAgg(
          referrerId: id,
          referrerName: (m['referrer_name'] ?? 'User').toString(),
          referrerPhone: (m['referrer_phone'] ?? '').toString(),
          referrerCode: (m['referrer_code'] ?? '').toString(),
        ),
      );
      agg.count++;
      if ((m['status'] ?? '') == 'reward_granted') {
        agg.rewarded++;
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return sorted
        .take(limit)
        .map(
          (e) => TopReferrerModel(
            referrerId: e.referrerId,
            referrerName: e.referrerName,
            referrerPhone: e.referrerPhone,
            referrerCode: e.referrerCode,
            count: e.count,
            rewarded: e.rewarded,
          ),
        )
        .toList();
  }

  Future<ReferEarnDashboardStats> aggregateStats() async {
    final referrals = await _db.collection('referrals').get();
    int invites = referrals.docs.length;
    int successful = 0;
    int pending = 0;
    int rewarded = 0;
    double discount = 0;

    for (final doc in referrals.docs) {
      final m = doc.data();
      final status = (m['status'] ?? '').toString();
      if (status == 'reward_granted') {
        successful++;
        rewarded++;
      } else if (status != 'rejected') {
        pending++;
      }
    }

    final campaigns = await _db.collection('refer_earn_campaigns').get();
    for (final c in campaigns.docs) {
      final stats = c.data()['stats'] as Map<String, dynamic>? ?? {};
      discount += (stats['total_discount_given'] as num?)?.toDouble() ?? 0;
    }

    return ReferEarnDashboardStats(
      totalInvitesSent: invites,
      totalSuccessful: successful,
      pendingReferrals: pending,
      rewardedReferrals: rewarded,
      totalDiscountGiven: discount,
      newUsersAcquired: invites,
    );
  }

  Future<void> adminAction({
    required String action,
    required String referralId,
    String? reason,
  }) async {
    final callable = _fn.httpsCallable('adminReferEarnActionCallable');
    await callable.call({
      'action': action,
      'referralId': referralId,
      if (reason != null) 'reason': reason,
    });
  }
}

class _ReferrerAgg {
  _ReferrerAgg({
    required this.referrerId,
    required this.referrerName,
    required this.referrerPhone,
    required this.referrerCode,
  });

  final String referrerId;
  final String referrerName;
  final String referrerPhone;
  final String referrerCode;
  int count = 0;
  int rewarded = 0;
}

class ReferEarnDashboardStats {
  const ReferEarnDashboardStats({
    required this.totalInvitesSent,
    required this.totalSuccessful,
    required this.pendingReferrals,
    required this.rewardedReferrals,
    required this.totalDiscountGiven,
    required this.newUsersAcquired,
  });

  final int totalInvitesSent;
  final int totalSuccessful;
  final int pendingReferrals;
  final int rewardedReferrals;
  final double totalDiscountGiven;
  final int newUsersAcquired;
}
