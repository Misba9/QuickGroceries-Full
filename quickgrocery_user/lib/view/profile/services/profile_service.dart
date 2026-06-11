import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';

class ProfileService extends ChangeNotifier {
  Future<String> createReferralLink(String referralCode) async {
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: "https://siswar.page.link",
      link: Uri.parse("https://siswar.com/referral?code=$referralCode"),
      androidParameters: const AndroidParameters(
        packageName: "com.quickgrocery.io",
        minimumVersion: 1,
      ),
    );

    final dynamicLink =
        await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
    return dynamicLink.shortUrl.toString();
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

    // Get all referred customers
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

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (kDebugMode) debugPrint('FCM Token: $token');
    }
  }
}
