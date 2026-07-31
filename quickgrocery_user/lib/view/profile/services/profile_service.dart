import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class ProfileService extends ChangeNotifier {
  /// HTTPS referral link (Universal Link / Hosting) — no Firebase Dynamic Links.
  static const String _referralBaseUrl =
      'https://www.quickgroceries.in/referral';

  Future<String> createReferralLink(String referralCode) async {
    final uri = Uri.parse(_referralBaseUrl).replace(
      queryParameters: {'code': referralCode},
    );
    return uri.toString();
  }

  void shareReferralLink(String referralCode) async {
    String link = await createReferralLink(referralCode);
    Share.share(
      'Get groceries delivered fast. Use my referral code $referralCode '
      'or link: $link',
    );
  }

  Future<double> getReferralProgress() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    QuerySnapshot referredCustomersSnapshot = await firestore
        .collection('customers')
        .where('referred_by', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();

    List<String> referredCustomerIds =
        referredCustomersSnapshot.docs.map((doc) => doc.id).toList();

    int completedReferrals = 0;

    for (String refCustomerId in referredCustomerIds) {
      QuerySnapshot orderSnapshot = await firestore
          .collection('cart')
          .where('uuid', isEqualTo: refCustomerId)
          .get();

      double totalSpent = orderSnapshot.docs
          .fold(0.0, (sum, doc) => sum + (doc['price'] as num).toDouble());

      if (totalSpent >= 500) {
        completedReferrals++;
      }

      if (completedReferrals >= 3) break;
    }

    double progress = completedReferrals / 3;
    return progress.clamp(0.0, 1.0);
  }

  Future<void> init() async {
    // Notification permission is requested after Home is ready via
    // [AppPermissionCoordinator.requestAfterAppReady] — do not prompt here.
    if (kDebugMode) debugPrint('ProfileService.init: no permission prompt');
  }
}
