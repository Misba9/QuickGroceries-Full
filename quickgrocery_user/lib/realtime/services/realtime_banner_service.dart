import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/view/home/data/services/banner_service.dart';

/// Thin alias service over [HomeBannerService] so the realtime layer
/// owns its own Firestore handle but doesn't duplicate the existing
/// banners stream. Keeps the home screen path stable and centralizes
/// "any banner-driven UI" under [RealtimeBannerService].
class RealtimeBannerService {
  RealtimeBannerService({FirebaseFirestore? firestore})
      : _delegate = HomeBannerService(firestore: firestore);

  final HomeBannerService _delegate;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveBanners({
    int? limit,
  }) {
    return _delegate.watchActiveBanners(limit: limit);
  }
}
