import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/firestore/global_app_settings.dart';

/// Persists [delivery_settings/default] for realtime sync with the user app.
///
/// Firestore canonical keys (see product spec):
/// - [freeDeliveryEnabled], [freeDeliveryThreshold]
/// - [deliveryChargesEnabled], [deliveryFee]
///
/// Legacy keys ([isFreeDeliveryEnabled], [isDeliveryChargesEnabled]) are still
/// written on save so older builds / scripts keep working.
class DeliverySettingsService extends ChangeNotifier {
  DeliverySettingsService() {
    void bump() => notifyListeners();
    freeDeliveryThresholdController.addListener(bump);
    deliveryFeeController.addListener(bump);
  }

  static const _collection = 'delivery_settings';
  static const _docId = 'default';

  final _firestore = FirebaseFirestore.instance;

  bool isLoading = false;
  bool isFreeDeliveryEnabled = true;
  bool isDeliveryChargesEnabled = true;
  final freeDeliveryThresholdController = TextEditingController(text: '149');
  final deliveryFeeController = TextEditingController(text: '25');

  /// From `settings/main` or `delivery_settings/default` after load.
  DateTime? lastUpdatedAt;

  int? get parsedThreshold =>
      int.tryParse(freeDeliveryThresholdController.text.trim());

  int? get parsedDeliveryFee =>
      int.tryParse(deliveryFeeController.text.trim());

  Future<void> fetch() async {
    isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _firestore
            .collection(GlobalAppSettings.collection)
            .doc(GlobalAppSettings.documentId)
            .get(),
        _firestore.collection(_collection).doc(_docId).get(),
      ]);

      final main = results[0].data() ?? const <String, dynamic>{};
      final def = results[1].data() ?? const <String, dynamic>{};
      final data = <String, dynamic>{...def};
      main.forEach((k, v) {
        if (v != null) data[k] = v;
      });

      isFreeDeliveryEnabled =
          data['freeDeliveryEnabled'] as bool? ??
              data['isFreeDeliveryEnabled'] as bool? ??
              true;
      isDeliveryChargesEnabled =
          data['deliveryChargesEnabled'] as bool? ??
                  data['deliveryFeeEnabled'] as bool? ??
              data['isDeliveryChargesEnabled'] as bool? ??
              true;
      freeDeliveryThresholdController.text =
          ((data['freeDeliveryThreshold'] as num?)?.toInt() ?? 149).toString();
      deliveryFeeController.text =
          ((data['deliveryFee'] as num?)?.toInt() ?? 25).toString();

      DateTime? ts;
      final mt = main['updatedAt'];
      if (mt is Timestamp) ts = mt.toDate();
      final dt = data['updatedAt'];
      if (ts == null && dt is Timestamp) ts = dt.toDate();
      lastUpdatedAt = ts;

      if (kDebugMode) {
        debugPrint(
          '[DeliverySettingsService] fetch → threshold=${freeDeliveryThresholdController.text} '
          'fee=${deliveryFeeController.text}',
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFreeDeliveryEnabled(bool value) {
    isFreeDeliveryEnabled = value;
    notifyListeners();
  }

  void setDeliveryChargesEnabled(bool value) {
    isDeliveryChargesEnabled = value;
    notifyListeners();
  }

  String freeDeliveryBannerPreview() {
    if (!isFreeDeliveryEnabled) {
      return 'Free delivery promos are turned off';
    }
    final t = parsedThreshold ?? 0;
    return '🚚 Free delivery above ₹$t';
  }

  String deliveryFeePreviewSentence() {
    if (!isDeliveryChargesEnabled) {
      return 'Delivery charges are disabled — customers pay ₹0 delivery.';
    }
    final t = parsedThreshold ?? 0;
    final f = parsedDeliveryFee ?? 0;
    return 'Orders below ₹$t will be charged ₹$f delivery fee.';
  }

  Future<void> save(BuildContext context) async {
    final threshold = int.tryParse(freeDeliveryThresholdController.text.trim());
    final deliveryFee = int.tryParse(deliveryFeeController.text.trim());

    if (threshold == null || deliveryFee == null) {
      _errorSnack(context, 'Please enter valid numbers for threshold and fee.');
      return;
    }
    if (threshold < 0 || deliveryFee < 0) {
      _errorSnack(context, 'Amounts cannot be negative.');
      return;
    }
    if (isFreeDeliveryEnabled && threshold < 1) {
      _errorSnack(
        context,
        'Free delivery threshold must be at least ₹1 when free delivery is on.',
      );
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      final payload = {
        'freeDeliveryEnabled': isFreeDeliveryEnabled,
        'freeDeliveryThreshold': threshold,
        'deliveryChargesEnabled': isDeliveryChargesEnabled,
        'deliveryFeeEnabled': isDeliveryChargesEnabled,
        'deliveryFee': deliveryFee,
        'updatedAt': FieldValue.serverTimestamp(),
        'isFreeDeliveryEnabled': isFreeDeliveryEnabled,
        'isDeliveryChargesEnabled': isDeliveryChargesEnabled,
      };

      await Future.wait([
        _firestore.collection(_collection).doc(_docId).set(
              payload,
              SetOptions(merge: true),
            ),
        _firestore
            .collection(GlobalAppSettings.collection)
            .doc(GlobalAppSettings.documentId)
            .set(
              payload,
              SetOptions(merge: true),
            ),
      ]);

      lastUpdatedAt = DateTime.now();
      if (kDebugMode) {
        debugPrint(
          '[DeliverySettingsService] save OK → settings/${GlobalAppSettings.documentId} '
          '+ delivery_settings/$_docId',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _errorSnack(context, 'Could not save: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _errorSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Text(msg),
      ),
    );
  }

  @override
  void dispose() {
    freeDeliveryThresholdController.dispose();
    deliveryFeeController.dispose();
    super.dispose();
  }
}
