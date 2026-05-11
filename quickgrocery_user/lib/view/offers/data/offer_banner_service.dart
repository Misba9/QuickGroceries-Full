import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/models/offer_banner_model.dart';

class OfferBannerService {
  OfferBannerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'offer_banners';
  static const String bannersCollection = 'banners';
  static const String settingsDocPath = 'app_settings/promotions';

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOfferBanners() {
    return _firestore.collection(collection).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchPromotionSettings() {
    return _firestore.doc(settingsDocPath).snapshots();
  }

  Future<void> incrementMetric(OfferBannerModel offer, {required bool click}) async {
    final col =
        offer.fromBannersCollection ? bannersCollection : collection;
    try {
      await _firestore.collection(col).doc(offer.id).update({
        if (click) 'clickCount': FieldValue.increment(1),
        if (!click) 'viewCount': FieldValue.increment(1),
      });
    } catch (_) {
      // Rules may omit counters on legacy docs — ignore.
    }
  }
}
