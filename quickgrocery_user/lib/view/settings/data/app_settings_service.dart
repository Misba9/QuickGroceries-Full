import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/view/cart/domain/cart_models.dart';

/// Firestore path for the global merged settings document (admin + user sync).
abstract final class AppSettingsPaths {
  static const collection = 'settings';
  static const documentId = 'main';
}

/// Realtime handle for [AppSettingsPaths] — used by [PricingService.watch].
class AppSettingsService {
  AppSettingsService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get mainRef => _firestore
      .collection(AppSettingsPaths.collection)
      .doc(AppSettingsPaths.documentId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMain() =>
      mainRef.snapshots();

  /// Applies `settings/main` fields on top of [base] (legacy + delivery_settings).
  static PricingConfig mergeMainDocument(
    PricingConfig base,
    Map<String, dynamic>? main,
  ) {
    if (main == null || main.isEmpty) return base;

    DateTime? updatedAt;
    final ts = main['updatedAt'];
    if (ts is Timestamp) updatedAt = ts.toDate();

    int resolveInt(String key, int current) {
      if (!main.containsKey(key)) return current;
      final v = main[key];
      return v is num ? v.toInt() : current;
    }

    bool resolveBool(
      String canonicalKey,
      String legacyKey,
      bool current,
    ) {
      final c = main[canonicalKey];
      if (c is bool) return c;
      final l = main[legacyKey];
      if (l is bool) return l;
      final alt = main['deliveryFeeEnabled'];
      if (canonicalKey == 'deliveryChargesEnabled' && alt is bool) {
        return alt;
      }
      return current;
    }

    bool resolveDeliveryChargesEnabled(bool current) {
      if (main.containsKey('deliveryChargesEnabled') &&
          main['deliveryChargesEnabled'] is bool) {
        return main['deliveryChargesEnabled'] as bool;
      }
      if (main.containsKey('dynamicDeliveryEnabled') &&
          main['dynamicDeliveryEnabled'] is bool) {
        return main['dynamicDeliveryEnabled'] as bool;
      }
      if (main['deliveryFeeEnabled'] is bool) {
        return main['deliveryFeeEnabled'] as bool;
      }
      if (main['isDeliveryChargesEnabled'] is bool) {
        return main['isDeliveryChargesEnabled'] as bool;
      }
      return resolveBool(
        'deliveryChargesEnabled',
        'isDeliveryChargesEnabled',
        current,
      );
    }

    int resolveDeliveryFee(int current) {
      if (!main.containsKey('deliveryFee') &&
          !main.containsKey('deliveryCharge')) {
        return current;
      }
      final v = main['deliveryFee'] ?? main['deliveryCharge'];
      return v is num ? v.toInt() : current;
    }

    return base.copyWith(
      platformFee: resolveInt('platformFee', base.platformFee),
      handlingCharge: resolveInt('handlingCharge', base.handlingCharge),
      freeDeliveryThreshold:
          resolveInt('freeDeliveryThreshold', base.freeDeliveryThreshold),
      standardDeliveryCharge: resolveDeliveryFee(base.standardDeliveryCharge),
      isFreeDeliveryEnabled: resolveBool(
        'freeDeliveryEnabled',
        'isFreeDeliveryEnabled',
        base.isFreeDeliveryEnabled,
      ),
      isDeliveryChargesEnabled: resolveDeliveryChargesEnabled(
        base.isDeliveryChargesEnabled,
      ),
      settingsUpdatedAt: updatedAt ?? base.settingsUpdatedAt,
    );
  }
}
