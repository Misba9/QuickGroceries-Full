import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/firestore/global_app_settings.dart';

/// Bundled platform / handling / delivery defaults on Firestore
/// `delivery_charge/{[platformFeeDocId]}` plus merged `settings/main` and
/// `delivery_settings/default` for realtime user app sync.
class PlatformFeeService extends ChangeNotifier {
  PlatformFeeService() {
    void bump() => notifyListeners();
    freeDeliveryThresholdController.addListener(bump);
  }

  bool isLoading = false;

  TextEditingController platformFeeController = TextEditingController();
  TextEditingController handlingChargeController = TextEditingController();
  TextEditingController deliveryChargeController = TextEditingController();
  TextEditingController freeDeliveryThresholdController =
      TextEditingController(text: '149');

  /// Legacy bundled fee document (unchanged path — all fields merged here).
  final String platformFeeDocId = 'r6ArqhMeZYDJnpFo6EJP';

  static const String _deliverySettingsCollection = 'delivery_settings';
  static const String _deliverySettingsDocId = 'default';

  final _firestore = FirebaseFirestore.instance;

  /// Last merged `updatedAt` for UI.
  DateTime? lastUpdatedAt;

  bool freeDeliveryEnabled = true;
  bool dynamicDeliveryEnabled = true;

  int? get parsedFreeThreshold =>
      int.tryParse(freeDeliveryThresholdController.text.trim());

  String freeDeliveryBannerPreview() {
    if (!freeDeliveryEnabled) {
      return 'Free delivery promos are turned off';
    }
    final t = parsedFreeThreshold ?? 0;
    return '🚚 Free delivery above ₹$t';
  }

  Future<void> fetchCharges() async {
    try {
      isLoading = true;
      notifyListeners();

      final results = await Future.wait([
        _firestore
            .collection(GlobalAppSettings.collection)
            .doc(GlobalAppSettings.documentId)
            .get(),
        _firestore.collection('delivery_charge').doc(platformFeeDocId).get(),
        _firestore
            .collection(_deliverySettingsCollection)
            .doc(_deliverySettingsDocId)
            .get(),
      ]);

      final main = results[0].data() ?? <String, dynamic>{};
      final legacy = results[1].data() ?? <String, dynamic>{};
      final deliveryDef = results[2].data() ?? <String, dynamic>{};

      final merged = <String, dynamic>{...legacy};
      deliveryDef.forEach((k, v) {
        if (v != null) merged[k] = v;
      });
      main.forEach((k, v) {
        if (v != null) merged[k] = v;
      });

      // Platform fee
      final mainFee = merged['platformFee'];
      if (mainFee is num) {
        platformFeeController.text = mainFee.toString();
      } else if (merged['amount'] != null) {
        platformFeeController.text = merged['amount'].toString();
      }

      // Handling & default delivery (legacy keys on same doc)
      final h = merged['handling_charge'] ?? merged['handlingCharge'];
      if (h is num) {
        handlingChargeController.text = h.toString();
      } else {
        handlingChargeController.text = '0';
      }

      final d = merged['delivery_charge'] ??
          merged['deliveryFee'] ??
          merged['deliveryCharge'];
      if (d is num) {
        deliveryChargeController.text = d.toString();
      } else {
        deliveryChargeController.text = '0';
      }

      // Free delivery block
      freeDeliveryEnabled =
          merged['freeDeliveryEnabled'] as bool? ??
              merged['isFreeDeliveryEnabled'] as bool? ??
              true;
      dynamicDeliveryEnabled =
          merged['dynamicDeliveryEnabled'] as bool? ??
              merged['deliveryChargesEnabled'] as bool? ??
              merged['deliveryFeeEnabled'] as bool? ??
              merged['isDeliveryChargesEnabled'] as bool? ??
              true;

      final th = merged['freeDeliveryThreshold'] ??
          merged['free_delivery_threshold'];
      if (th is num) {
        freeDeliveryThresholdController.text = th.toInt().toString();
      }

      DateTime? ts;
      for (final raw in [
        main['updatedAt'],
        merged['updatedAt'],
        deliveryDef['updatedAt'],
      ]) {
        if (raw is Timestamp) {
          ts = raw.toDate();
          break;
        }
      }
      lastUpdatedAt = ts;

      if (kDebugMode) {
        debugPrint(
          '[PlatformFeeService] fetchCharges → platform=${platformFeeController.text} '
          'handling=${handlingChargeController.text} delivery=${deliveryChargeController.text}',
        );
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('[PlatformFeeService] fetch error: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  void setFreeDeliveryEnabled(bool value) {
    freeDeliveryEnabled = value;
    notifyListeners();
  }

  void setDynamicDeliveryEnabled(bool value) {
    dynamicDeliveryEnabled = value;
    notifyListeners();
  }

  Future<void> updateCharges(BuildContext context) async {
    if (platformFeeController.text.isEmpty) {
      _snack(context, 'Platform fee cannot be empty.', isError: true);
      return;
    }

    final platformFee = double.tryParse(platformFeeController.text);
    if (platformFee == null || platformFee < 0) {
      _snack(
        context,
        'Please enter a valid platform fee amount.',
        isError: true,
      );
      return;
    }

    final handling = double.tryParse(handlingChargeController.text.trim());
    final delivery = double.tryParse(deliveryChargeController.text.trim());
    if (handling == null || handling < 0) {
      _snack(context, 'Please enter a valid handling charge.', isError: true);
      return;
    }
    if (delivery == null || delivery < 0) {
      _snack(
        context,
        'Please enter a valid default delivery charge.',
        isError: true,
      );
      return;
    }

    final threshold = int.tryParse(freeDeliveryThresholdController.text.trim());
    if (threshold == null) {
      _snack(context, 'Please enter a valid free delivery threshold.', isError: true);
      return;
    }
    if (freeDeliveryEnabled && threshold < 1) {
      _snack(
        context,
        'Free delivery threshold must be at least ₹1 when free delivery is on.',
        isError: true,
      );
      return;
    }

    final feeInt = platformFee.round();
    final handlingInt = handling.round();
    final deliveryInt = delivery.round();

    try {
      isLoading = true;
      notifyListeners();

      final legacyPayload = <String, dynamic>{
        'amount': platformFee,
        'handling_charge': handlingInt,
        'delivery_charge': deliveryInt,
        'free_delivery_threshold': threshold,
        'freeDeliveryEnabled': freeDeliveryEnabled,
        'freeDeliveryThreshold': threshold,
        'dynamicDeliveryEnabled': dynamicDeliveryEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final settingsMainPayload = <String, dynamic>{
        'platformFee': feeInt,
        'handlingCharge': handlingInt,
        'deliveryCharge': deliveryInt,
        'deliveryFee': deliveryInt,
        'freeDeliveryEnabled': freeDeliveryEnabled,
        'freeDeliveryThreshold': threshold,
        'dynamicDeliveryEnabled': dynamicDeliveryEnabled,
        'deliveryChargesEnabled': dynamicDeliveryEnabled,
        'deliveryFeeEnabled': dynamicDeliveryEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final deliverySettingsPayload = <String, dynamic>{
        'freeDeliveryEnabled': freeDeliveryEnabled,
        'freeDeliveryThreshold': threshold,
        'deliveryChargesEnabled': dynamicDeliveryEnabled,
        'deliveryFeeEnabled': dynamicDeliveryEnabled,
        'deliveryFee': deliveryInt,
        'updatedAt': FieldValue.serverTimestamp(),
        'isFreeDeliveryEnabled': freeDeliveryEnabled,
        'isDeliveryChargesEnabled': dynamicDeliveryEnabled,
      };

      await Future.wait([
        _firestore.collection('delivery_charge').doc(platformFeeDocId).set(
              legacyPayload,
              SetOptions(merge: true),
            ),
        _firestore
            .collection(GlobalAppSettings.collection)
            .doc(GlobalAppSettings.documentId)
            .set(
              settingsMainPayload,
              SetOptions(merge: true),
            ),
        _firestore
            .collection(_deliverySettingsCollection)
            .doc(_deliverySettingsDocId)
            .set(
              deliverySettingsPayload,
              SetOptions(merge: true),
            ),
      ]);

      lastUpdatedAt = DateTime.now();
      if (kDebugMode) {
        debugPrint(
          '[PlatformFeeService] save OK → delivery_charge/$platformFeeDocId + '
          'settings/${GlobalAppSettings.documentId} + delivery_settings/$_deliverySettingsDocId',
        );
      }

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        _snack(context, 'Settings updated successfully.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PlatformFeeService] save error: $e');
      isLoading = false;
      notifyListeners();
      if (context.mounted) {
        _snack(context, 'Could not save: $e', isError: true);
      }
    }
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade800 : null,
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    platformFeeController.dispose();
    handlingChargeController.dispose();
    deliveryChargeController.dispose();
    freeDeliveryThresholdController.dispose();
    super.dispose();
  }
}
