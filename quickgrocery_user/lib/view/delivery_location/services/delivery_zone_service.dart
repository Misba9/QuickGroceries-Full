import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/delivery/delivery_zone_lookup.dart';
import 'package:quickgrocery/models/delivery_zone_model.dart';

class DeliveryZoneService extends ChangeNotifier {
  DeliveryZoneService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  List<DeliveryZoneModel> _deliveryZones = [];
  bool _isLoading = false;
  bool _lastLookupFailed = false;
  bool? _hasActiveZonesCache;

  List<DeliveryZoneModel> get deliveryZones => _deliveryZones;
  bool get isLoading => _isLoading;
  bool get lastLookupFailed => _lastLookupFailed;

  /// Fetch all delivery zones from Firestore
  Future<void> fetchDeliveryZones() async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('delivery_zones')
          .orderBy('created_at', descending: true)
          .get();

      _deliveryZones = snapshot.docs.map((doc) {
        return DeliveryZoneModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _hasActiveZonesCache =
          _deliveryZones.any((zone) => zone.isActive && zone.pinCodes.isNotEmpty);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching delivery zones: $e');
    }
  }

  Future<bool> hasActiveDeliveryZones() async {
    if (_hasActiveZonesCache != null) return _hasActiveZonesCache!;
    _hasActiveZonesCache = await DeliveryZoneLookup.hasActiveZones(_firestore);
    return _hasActiveZonesCache!;
  }

  void invalidateCache() {
    _hasActiveZonesCache = null;
  }

  /// Returns the first active zone that contains the pin code, or null if not found.
  Future<DeliveryZoneModel?> getZoneByPinCode(String pinCode) async {
    try {
      _lastLookupFailed = false;
      return await DeliveryZoneLookup.findActiveZoneByPin(_firestore, pinCode);
    } catch (e) {
      _lastLookupFailed = true;
      debugPrint('Error getting zone by pin code: $e');
      return null;
    }
  }

  Future<DeliveryZoneCheckResult> checkPinCode(String pinCode) async {
    final pin = DeliveryZoneLookup.normalizePin(pinCode);
    if (pin.isEmpty) {
      final hasZones = await hasActiveDeliveryZones();
      return hasZones
          ? DeliveryZoneCheckResult.missingPin
          : DeliveryZoneCheckResult.noZonesConfigured;
    }

    try {
      _lastLookupFailed = false;
      final hasZones = await hasActiveDeliveryZones();
      if (!hasZones) {
        return DeliveryZoneCheckResult.noZonesConfigured;
      }

      final zone = await DeliveryZoneLookup.findActiveZoneByPin(_firestore, pin);
      return zone != null
          ? DeliveryZoneCheckResult.serviceable
          : DeliveryZoneCheckResult.notServiceable;
    } catch (e) {
      _lastLookupFailed = true;
      debugPrint('Error checking pin code: $e');
      return DeliveryZoneCheckResult.lookupFailed;
    }
  }

  /// Check if a pin code is serviceable
  Future<bool> isPinCodeServiceable(String pinCode) async {
    final result = await checkPinCode(pinCode);
    return result == DeliveryZoneCheckResult.serviceable ||
        result == DeliveryZoneCheckResult.noZonesConfigured;
  }
}
