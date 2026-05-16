import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import '../../settings/data/app_settings_service.dart';
import '../domain/cart_models.dart';

/// Reads platform-wide pricing knobs from Firestore.
///
/// **Realtime:** listens to `settings/main`, `delivery_settings/default`,
/// `app_config/pricing`, and every `delivery_charge` document used in [fetch]
/// so admin updates (platform fee, delivery fee, thresholds) propagate
/// immediately without app restart.
///
/// `settings/main` overrides legacy fields when present (merge-friendly).
class PricingService {
  PricingService(this._firestore);

  final FirebaseFirestore _firestore;

  static const _standardDocId = 'b1slJi5ePvTQ5JHeYtWx';
  static const _minOrderDocId = 'dpKk0Q4CNNwgUlltn6OM';
  static const _platformDocId = 'r6ArqhMeZYDJnpFo6EJP';
  static const _deliverySettingsDocId = 'default';

  /// Swallows per-document stream errors so [Rx.merge] never tears down the
  /// whole pricing stream (which would surface as [AsyncError] on the home page).
  Stream<DocumentSnapshot<Map<String, dynamic>>> _guardDoc(
    Stream<DocumentSnapshot<Map<String, dynamic>>> raw,
  ) {
    return raw.transform(
      StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
          DocumentSnapshot<Map<String, dynamic>>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (
          Object error,
          StackTrace stackTrace,
          EventSink<DocumentSnapshot<Map<String, dynamic>>> sink,
        ) {
          if (kDebugMode) {
            debugPrint(
              '[PricingService] doc stream soft-fail (${error.runtimeType}): $error',
            );
          }
        },
        handleDone: (sink) => sink.close(),
      ),
    );
  }

  Future<PricingConfig> fetch() async {
    try {
      return await _fetchUnchecked();
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PricingService] fetch FirebaseException: $e\n$st');
      }
      return const PricingConfig();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PricingService] fetch failed: $e\n$st');
      }
      return const PricingConfig();
    }
  }

  Future<PricingConfig> _fetchUnchecked() async {
    final results = await Future.wait([
      _firestore.collection('delivery_charge').doc(_standardDocId).get(),
      _firestore.collection('delivery_charge').doc(_minOrderDocId).get(),
      _firestore.collection('delivery_charge').doc(_platformDocId).get(),
      _firestore.collection('app_config').doc('pricing').get(),
      _firestore
          .collection('delivery_settings')
          .doc(_deliverySettingsDocId)
          .get(),
      _firestore
          .collection(AppSettingsPaths.collection)
          .doc(AppSettingsPaths.documentId)
          .get(),
    ]);

    final standardDoc = results[0].data() ?? const {};
    final minOrderDoc = results[1].data() ?? const {};
    final platformDoc = results[2].data() ?? const {};
    final appConfig = results[3].data() ?? const {};
    final deliverySettings = results[4].data() ?? const {};
    final mainSettings = results[5].data() ?? const {};

    final standard = (standardDoc['amount'] as num?)?.toInt() ?? 0;
    final minOrder = (minOrderDoc['amount'] as num?)?.toInt() ?? 100;
    final platformFee = (platformDoc['amount'] as num?)?.toInt() ?? 0;
    final handlingFromPlatform =
        (platformDoc['handling_charge'] as num?)?.toInt() ??
            (platformDoc['handlingCharge'] as num?)?.toInt() ??
            0;
    final deliveryDefault =
        (platformDoc['delivery_charge'] as num?)?.toInt() ?? 0;
    final freeThresholdLegacy =
        (platformDoc['free_delivery_threshold'] as num?)?.toInt() ?? 99;
    final freeThresholdCamel =
        (platformDoc['freeDeliveryThreshold'] as num?)?.toInt();
    final freeThresholdPlatform = freeThresholdCamel ?? freeThresholdLegacy;

    final adminThreshold =
        (deliverySettings['freeDeliveryThreshold'] as num?)?.toInt();
    final adminDeliveryFee = (deliverySettings['deliveryFee'] as num?)?.toInt();
    final freeDeliveryEnabledFromDelivery =
        deliverySettings['freeDeliveryEnabled'] as bool? ??
            deliverySettings['isFreeDeliveryEnabled'] as bool?;
    final deliveryFeeEnabledFromDelivery =
        deliverySettings['deliveryChargesEnabled'] as bool? ??
            deliverySettings['isDeliveryChargesEnabled'] as bool?;

    final freeDeliveryEnabledFromPlatform =
        platformDoc['freeDeliveryEnabled'] as bool? ??
            platformDoc['isFreeDeliveryEnabled'] as bool?;
    final dynamicDeliveryFromPlatform =
        platformDoc['dynamicDeliveryEnabled'] as bool?;
    final deliveryFeeEnabledFromPlatform =
        platformDoc['deliveryChargesEnabled'] as bool? ??
            platformDoc['deliveryFeeEnabled'] as bool? ??
            platformDoc['isDeliveryChargesEnabled'] as bool?;

    final freeDeliveryEnabled = freeDeliveryEnabledFromDelivery ??
        freeDeliveryEnabledFromPlatform ??
        true;
    final deliveryFeeEnabled = deliveryFeeEnabledFromDelivery ??
        dynamicDeliveryFromPlatform ??
        deliveryFeeEnabledFromPlatform ??
        true;

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

    final base = PricingConfig(
      platformFee: platformFee,
      handlingCharge: handlingFromPlatform,
      defaultDeliveryCharge: deliveryDefault,
      standardDeliveryCharge: adminDeliveryFee ??
          (deliveryDefault > 0 ? deliveryDefault : standard),
      minOrderValue: minOrder,
      freeDeliveryThreshold: adminThreshold ?? freeThresholdPlatform,
      isFreeDeliveryEnabled: freeDeliveryEnabled,
      isDeliveryChargesEnabled: deliveryFeeEnabled,
      taxPercent: taxPercent,
      surgeMultiplier: surgeMultiplier,
      surgeActive: surgeActive,
      surgeReason: surgeReason,
    );

    final merged = AppSettingsService.mergeMainDocument(base, mainSettings);

    if (kDebugMode) {
      debugPrint(
        '[PricingService] fetch → platformFee=${merged.platformFee} '
        'threshold=${merged.freeDeliveryThreshold} delivery=${merged.standardDeliveryCharge} '
        'freeOn=${merged.isFreeDeliveryEnabled} chargesOn=${merged.isDeliveryChargesEnabled}',
      );
    }

    return merged;
  }

  /// Emits a new [PricingConfig] whenever any backing document changes.
  Stream<PricingConfig> watch() async* {
    var lastKnown = await fetch();
    yield lastKnown;

    final paths = <Stream<DocumentSnapshot<Map<String, dynamic>>>>[
      _guardDoc(_firestore.collection('app_config').doc('pricing').snapshots()),
      _guardDoc(
        _firestore
            .collection('delivery_settings')
            .doc(_deliverySettingsDocId)
            .snapshots(),
      ),
      _guardDoc(
        _firestore
            .collection(AppSettingsPaths.collection)
            .doc(AppSettingsPaths.documentId)
            .snapshots(),
      ),
      _guardDoc(
        _firestore.collection('delivery_charge').doc(_platformDocId).snapshots(),
      ),
      _guardDoc(
        _firestore.collection('delivery_charge').doc(_standardDocId).snapshots(),
      ),
      _guardDoc(
        _firestore.collection('delivery_charge').doc(_minOrderDocId).snapshots(),
      ),
    ];

    yield* Rx.merge(paths).asyncMap((snap) async {
      if (kDebugMode) {
        debugPrint('[PricingService] snapshot → ${snap.reference.path}');
      }
      lastKnown = await fetch();
      return lastKnown;
    });
  }
}
