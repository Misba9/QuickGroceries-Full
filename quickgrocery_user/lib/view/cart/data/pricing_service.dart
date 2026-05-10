import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cart_models.dart';

/// Reads platform-wide pricing knobs from Firestore.
///
/// Compatible with the existing `delivery_charge` collection laid out in the
/// legacy `CartService.getDeliveryCharge` (three docs: standard fee, min order
/// amount, and a "platform fee" doc that bundles platform/handling/delivery).
///
/// Surge + tax are read from a new optional `app_config/pricing` document with
/// the shape:
/// ```
/// {
///   taxPercent: 0,
///   surge: { multiplier: 1.5, isActive: false, reason: "Heavy rain" }
/// }
/// ```
/// Both blocks are optional — missing = no surge, no tax.
class PricingService {
  PricingService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _standardDocId = 'b1slJi5ePvTQ5JHeYtWx';
  static const _minOrderDocId = 'dpKk0Q4CNNwgUlltn6OM';
  static const _platformDocId = 'r6ArqhMeZYDJnpFo6EJP';

  Future<PricingConfig> fetch() async {
    final results = await Future.wait([
      _firestore.collection('delivery_charge').doc(_standardDocId).get(),
      _firestore.collection('delivery_charge').doc(_minOrderDocId).get(),
      _firestore.collection('delivery_charge').doc(_platformDocId).get(),
      _firestore.collection('app_config').doc('pricing').get(),
    ]);

    final standardDoc = results[0].data() ?? const {};
    final minOrderDoc = results[1].data() ?? const {};
    final platformDoc = results[2].data() ?? const {};
    final appConfig = results[3].data() ?? const {};

    final standard = (standardDoc['amount'] as num?)?.toInt() ?? 0;
    final minOrder = (minOrderDoc['amount'] as num?)?.toInt() ?? 100;
    final platformFee = (platformDoc['amount'] as num?)?.toInt() ?? 0;
    final handling = (platformDoc['handling_charge'] as num?)?.toInt() ?? 0;
    final deliveryDefault =
        (platformDoc['delivery_charge'] as num?)?.toInt() ?? 0;
    final freeThreshold =
        (platformDoc['free_delivery_threshold'] as num?)?.toInt() ?? 99;

    final taxPercent = (appConfig['taxPercent'] as num?)?.toDouble() ?? 0;

    final surgeRaw = appConfig['surge'];
    var surgeActive = false;
    var surgeMultiplier = 1.0;
    String? surgeReason;
    if (surgeRaw is Map) {
      surgeActive = surgeRaw['isActive'] as bool? ?? false;
      surgeMultiplier =
          (surgeRaw['multiplier'] as num?)?.toDouble() ?? 1.0;
      surgeReason = surgeRaw['reason']?.toString();
    }

    return PricingConfig(
      platformFee: platformFee,
      handlingCharge: handling,
      defaultDeliveryCharge: deliveryDefault,
      standardDeliveryCharge: standard,
      minOrderValue: minOrder,
      freeDeliveryThreshold: freeThreshold,
      taxPercent: taxPercent,
      surgeMultiplier: surgeMultiplier,
      surgeActive: surgeActive,
      surgeReason: surgeReason,
    );
  }

  /// Live stream of the surge config so the cart updates in real time during
  /// surges (e.g. heavy rain banner appears the moment ops flips it).
  Stream<PricingConfig> watch() async* {
    yield await fetch();
    yield* _firestore
        .collection('app_config')
        .doc('pricing')
        .snapshots()
        .asyncMap((_) => fetch());
  }
}
