import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:quickgrocery/core/firebase/callable_payload.dart';

/// How the referral screen should present itself after loading.
enum ReferEarnLoadState {
  /// Full dashboard from Cloud Functions.
  ready,

  /// Program disabled in admin settings.
  unavailable,

  /// Functions not deployed / not found — friendly coming-soon UI.
  comingSoon,

  /// Device offline or unreachable host.
  networkError,

  /// Partial data from Firestore when callables are unavailable.
  partial,
}

class ReferEarnLoadResult {
  const ReferEarnLoadResult({
    required this.state,
    required this.data,
  });

  final ReferEarnLoadState state;
  final ReferEarnDashboard data;

  bool get showDashboard =>
      state == ReferEarnLoadState.ready || state == ReferEarnLoadState.partial;

  bool get showComingSoon => state == ReferEarnLoadState.comingSoon;

  bool get showUnavailable => state == ReferEarnLoadState.unavailable;

  bool get showNetworkError => state == ReferEarnLoadState.networkError;
}

class ReferralHistoryItem {
  const ReferralHistoryItem({
    required this.id,
    required this.friendName,
    required this.joinedDate,
    required this.status,
    required this.statusLabel,
    required this.rewardStatus,
  });

  final String id;
  final String friendName;
  final DateTime? joinedDate;
  final String status;
  final String statusLabel;
  final String rewardStatus;

  factory ReferralHistoryItem.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ReferralHistoryItem(
      id: (m['id'] ?? '').toString(),
      friendName: (m['friendName'] ?? 'Friend').toString(),
      joinedDate: parseDate(m['joinedDate']),
      status: (m['status'] ?? '').toString(),
      statusLabel: (m['statusLabel'] ?? '').toString(),
      rewardStatus: (m['rewardStatus'] ?? 'none').toString(),
    );
  }
}

class ReferEarnDashboard {
  const ReferEarnDashboard({
    required this.referralCode,
    required this.enabled,
    required this.canShare,
    required this.playStoreUrl,
    required this.shareMessage,
    required this.referrerReward,
    required this.friendReward,
    required this.minOrderValue,
    required this.campaignName,
    required this.invitesSent,
    required this.joinedCount,
    required this.orderedCount,
    required this.pendingReferrals,
    required this.successfulReferrals,
    required this.totalRewardsEarned,
    required this.history,
  });

  final String referralCode;
  final bool enabled;
  final bool canShare;
  final String playStoreUrl;
  final String shareMessage;
  final int referrerReward;
  final int friendReward;
  final int minOrderValue;
  final String campaignName;
  final int invitesSent;
  final int joinedCount;
  final int orderedCount;
  final int pendingReferrals;
  final int successfulReferrals;
  final double totalRewardsEarned;
  final List<ReferralHistoryItem> history;

  static ReferEarnDashboard fallback({String? referralCode}) => ReferEarnDashboard(
        referralCode: referralCode ?? '',
        enabled: false,
        canShare: false,
        playStoreUrl: '',
        shareMessage: '',
        referrerReward: 50,
        friendReward: 50,
        minOrderValue: 199,
        campaignName: '',
        invitesSent: 0,
        joinedCount: 0,
        orderedCount: 0,
        pendingReferrals: 0,
        successfulReferrals: 0,
        totalRewardsEarned: 0,
        history: const [],
      );

  @Deprecated('Use ReferEarnDashboard.fallback')
  static const empty = ReferEarnDashboard(
    referralCode: '',
    enabled: false,
    canShare: false,
    playStoreUrl: '',
    shareMessage: '',
    referrerReward: 50,
    friendReward: 50,
    minOrderValue: 199,
    campaignName: '',
    invitesSent: 0,
    joinedCount: 0,
    orderedCount: 0,
    pendingReferrals: 0,
    successfulReferrals: 0,
    totalRewardsEarned: 0,
    history: [],
  );

  factory ReferEarnDashboard.fromMap(Map<String, dynamic> m) {
    final rawHistory = m['history'];
    final history = <ReferralHistoryItem>[];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map) {
          history.add(
            ReferralHistoryItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return ReferEarnDashboard(
      referralCode: (m['referralCode'] ?? '').toString(),
      enabled: m['enabled'] == true,
      canShare: m['canShare'] == true,
      playStoreUrl: (m['playStoreUrl'] ?? '').toString(),
      shareMessage: (m['shareMessage'] ?? '').toString(),
      referrerReward: (m['referrerReward'] as num?)?.toInt() ?? 50,
      friendReward: (m['friendReward'] as num?)?.toInt() ??
          (m['newUserReward'] as num?)?.toInt() ??
          50,
      minOrderValue: (m['minOrderValue'] as num?)?.toInt() ?? 199,
      campaignName: (m['campaignName'] ?? '').toString(),
      invitesSent: (m['invitesSent'] as num?)?.toInt() ??
          (m['totalReferrals'] as num?)?.toInt() ??
          (m['totalInvites'] as num?)?.toInt() ??
          0,
      joinedCount: (m['joinedCount'] as num?)?.toInt() ?? 0,
      orderedCount: (m['orderedCount'] as num?)?.toInt() ?? 0,
      pendingReferrals: (m['pendingReferrals'] as num?)?.toInt() ?? 0,
      successfulReferrals: (m['successfulReferrals'] as num?)?.toInt() ?? 0,
      totalRewardsEarned: (m['totalRewardsEarned'] as num?)?.toDouble() ??
          (m['rewardsEarned'] as num?)?.toDouble() ??
          0,
      history: history,
    );
  }
}

/// @deprecated Use [ReferEarnDashboard].
typedef ReferEarnStats = ReferEarnDashboard;

/// Region must match deployed Cloud Functions (`us-central1`).
const _functionsRegion = 'us-central1';

const _dashboardCallableNames = [
  'getReferralDashboard',
  'getReferEarnStatsCallable',
];

const _generateCodeCallableNames = [
  'generateReferralCode',
  'ensureReferralCodeCallable',
];

class ReferEarnService {
  ReferEarnService({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _functionsRegion,
            ),
        _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _fn;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static void _log(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ReferEarn] $message${error != null ? ': $error' : ''}');
    }
  }

  bool _firebaseReady() {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  bool _isFunctionsMissing(FirebaseFunctionsException e) {
    return e.code == 'not-found' ||
        e.code == 'unimplemented' ||
        (e.message?.toLowerCase().contains('not-found') ?? false);
  }

  bool _isNetworkIssue(FirebaseFunctionsException e) {
    return e.code == 'unavailable' ||
        e.code == 'deadline-exceeded' ||
        e.code == 'internal';
  }

  Future<Map<String, dynamic>?> _invokeFirstCallable(
    List<String> names,
    Map<String, dynamic> payload,
  ) async {
    FirebaseFunctionsException? lastFnError;

    for (final name in names) {
      try {
        final result = await _fn.httpsCallable(name).call(
              sanitizeCallableData(payload),
            );
        final raw = result.data;
        if (raw == null) {
          _log('Callable $name returned null');
          continue;
        }
        if (raw is Map) {
          return Map<String, dynamic>.from(raw);
        }
        _log('Callable $name returned non-map: ${raw.runtimeType}');
      } on FirebaseFunctionsException catch (e) {
        lastFnError = e;
        _log('Callable $name failed (${e.code})', e.message);
        if (_isFunctionsMissing(e)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastFnError != null) throw lastFnError;
    return null;
  }

  /// Safe load — never throws; returns UI state + data.
  Future<ReferEarnLoadResult> loadDashboard({String? name}) async {
    if (!_firebaseReady()) {
      _log('Firebase not initialized');
      return ReferEarnLoadResult(
        state: ReferEarnLoadState.comingSoon,
        data: ReferEarnDashboard.fallback(),
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      return ReferEarnLoadResult(
        state: ReferEarnLoadState.comingSoon,
        data: ReferEarnDashboard.fallback(),
      );
    }

    if (!await _hasNetwork()) {
      final offline = await _loadFromFirestore(user.uid);
      return ReferEarnLoadResult(
        state: ReferEarnLoadState.networkError,
        data: offline ?? ReferEarnDashboard.fallback(),
      );
    }

    try {
      final map = await _invokeFirstCallable(
        _dashboardCallableNames,
        {if (name != null) 'name': name},
      );

      if (map == null) {
        final fallback = await _loadFromFirestore(user.uid);
        if (fallback != null && fallback.referralCode.isNotEmpty) {
          return ReferEarnLoadResult(
            state: ReferEarnLoadState.partial,
            data: fallback,
          );
        }
        return ReferEarnLoadResult(
          state: ReferEarnLoadState.comingSoon,
          data: ReferEarnDashboard.fallback(
            referralCode: await _localReferralCode(user.uid),
          ),
        );
      }

      final dashboard = ReferEarnDashboard.fromMap(map);

      if (!dashboard.enabled) {
        return ReferEarnLoadResult(
          state: ReferEarnLoadState.unavailable,
          data: dashboard,
        );
      }

      return ReferEarnLoadResult(
        state: ReferEarnLoadState.ready,
        data: dashboard,
      );
    } on FirebaseFunctionsException catch (e) {
      _log('loadDashboard functions error', e);

      if (_isNetworkIssue(e)) {
        final offline = await _loadFromFirestore(user.uid);
        return ReferEarnLoadResult(
          state: ReferEarnLoadState.networkError,
          data: offline ?? ReferEarnDashboard.fallback(),
        );
      }

      if (_isFunctionsMissing(e)) {
        final fallback = await _loadFromFirestore(user.uid);
        if (fallback != null && fallback.referralCode.isNotEmpty) {
          return ReferEarnLoadResult(
            state: ReferEarnLoadState.partial,
            data: fallback,
          );
        }
        return ReferEarnLoadResult(
          state: ReferEarnLoadState.comingSoon,
          data: ReferEarnDashboard.fallback(
            referralCode: await _localReferralCode(user.uid),
          ),
        );
      }

      return ReferEarnLoadResult(
        state: ReferEarnLoadState.comingSoon,
        data: ReferEarnDashboard.fallback(),
      );
    } catch (e, st) {
      _log('loadDashboard unexpected error', e);
      if (kDebugMode) debugPrint('$st');
      final fallback = await _loadFromFirestore(user.uid);
      return ReferEarnLoadResult(
        state: ReferEarnLoadState.comingSoon,
        data: fallback ?? ReferEarnDashboard.fallback(),
      );
    }
  }

  Future<ReferEarnDashboard> fetchDashboard({String? name}) async {
    final result = await loadDashboard(name: name);
    return result.data;
  }

  Future<ReferEarnDashboard> fetchStats({String? name}) => fetchDashboard(name: name);

  Future<String> ensureReferralCode({String? name}) async {
    if (!_firebaseReady()) return '';

    try {
      final map = await _invokeFirstCallable(
        _generateCodeCallableNames,
        {if (name != null) 'name': name},
      );
      final code = (map?['referralCode'] ?? '').toString();
      if (code.isNotEmpty) return code;
    } on FirebaseFunctionsException catch (e) {
      _log('ensureReferralCode', e);
    } catch (e) {
      _log('ensureReferralCode', e);
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return '';
    return _localReferralCode(uid);
  }

  Future<({bool ok, String message})> applyReferralCode(String code) async {
    if (!_firebaseReady()) {
      return (ok: false, message: 'Referral service is unavailable.');
    }

    try {
      final result = await _fn.httpsCallable('applyReferralCodeCallable').call(
            sanitizeCallableData({'code': code.trim()}),
          );
      final raw = result.data;
      if (raw is! Map) {
        return (ok: false, message: 'Invalid response from server.');
      }
      final data = Map<String, dynamic>.from(raw);
      return (
        ok: data['ok'] == true,
        message: (data['message'] ?? '').toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      _log('applyReferralCode', e);
      if (_isFunctionsMissing(e)) {
        return (
          ok: false,
          message: 'Referral program is not available yet. Please try later.',
        );
      }
      return (ok: false, message: 'Could not apply referral code. Try again.');
    } catch (e) {
      _log('applyReferralCode', e);
      return (ok: false, message: 'Could not apply referral code. Try again.');
    }
  }

  Stream<bool> watchSystemEnabled() {
    if (!_firebaseReady()) {
      return Stream.value(false);
    }
    return _db.doc('refer_earn_settings/global').snapshots().map((s) {
      return s.data()?['enabled'] == true;
    }).handleError((_) => false);
  }

  Future<String> _localReferralCode(String uid) async {
    try {
      final doc = await _db.collection('customers').doc(uid).get();
      final code = doc.data()?['referral_code']?.toString();
      if (code != null && code.isNotEmpty && code != uid) {
        return code.toUpperCase();
      }
    } catch (e) {
      _log('localReferralCode', e);
    }
    return uid.length >= 6 ? uid.substring(0, 6).toUpperCase() : uid.toUpperCase();
  }

  Future<ReferEarnDashboard?> _loadFromFirestore(String uid) async {
    try {
      final settingsSnap = await _db.doc('refer_earn_settings/global').get();
      final settings = settingsSnap.data() ?? {};
      final enabled = settings['enabled'] == true;
      final playStore = (settings['play_store_url'] ?? '').toString();
      final friendReward =
          (settings['new_user_reward_amount'] as num?)?.toInt() ?? 50;
      final referrerReward =
          (settings['referrer_reward_amount'] as num?)?.toInt() ?? 50;
      final minOrder = (settings['minimum_order_value'] as num?)?.toInt() ?? 199;

      final code = await _localReferralCode(uid);

      final referrals = await _db
          .collection('referrals')
          .where('referrer_id', isEqualTo: uid)
          .limit(25)
          .get();

      final history = <ReferralHistoryItem>[];
      var pending = 0;
      var successful = 0;

      for (final doc in referrals.docs) {
        final m = doc.data();
        final status = (m['status'] ?? '').toString();
        if (status == 'rejected' || m['disabled'] == true) continue;
        if (status == 'reward_granted') {
          successful++;
        } else {
          pending++;
        }

        DateTime? joined;
        final signup = m['signup_date'] ?? m['referral_date'];
        if (signup is Timestamp) joined = signup.toDate();

        history.add(
          ReferralHistoryItem(
            id: doc.id,
            friendName: (m['referred_user_name'] ?? 'Friend').toString(),
            joinedDate: joined,
            status: status,
            statusLabel: _statusLabel(status),
            rewardStatus: (m['reward_status'] ?? 'none').toString(),
          ),
        );
      }

      final shareMessage = playStore.isNotEmpty
          ? 'Get groceries delivered in minutes with Quick Groceries.\n\n'
              'Use my referral code $code and get ₹$friendReward OFF on your first order.\n\n'
              'Download App:\n$playStore'
          : '';

      return ReferEarnDashboard(
        referralCode: code,
        enabled: enabled,
        canShare: playStore.isNotEmpty,
        playStoreUrl: playStore,
        shareMessage: shareMessage,
        referrerReward: referrerReward,
        friendReward: friendReward,
        minOrderValue: minOrder,
        campaignName: '',
        invitesSent: referrals.docs.length,
        joinedCount: referrals.docs.length,
        orderedCount: successful,
        pendingReferrals: pending,
        successfulReferrals: successful,
        totalRewardsEarned: successful * referrerReward.toDouble(),
        history: history,
      );
    } catch (e) {
      _log('loadFromFirestore', e);
      return null;
    }
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'first_order_pending':
        return 'Joined';
      case 'reward_eligible':
        return 'First Order Completed';
      case 'reward_granted':
        return 'Reward Granted';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
