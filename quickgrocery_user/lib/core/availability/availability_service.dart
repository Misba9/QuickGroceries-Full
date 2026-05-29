import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/maintenance/data/maintenance_repository.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_config.dart';
import 'package:quickgrocery/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/view/cart/data/order_inventory_validator.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/providers/order_repository_provider.dart';

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  return AvailabilityService(
    maintenanceRepository: ref.watch(maintenanceRepositoryProvider),
    inventoryValidator: ref.watch(orderInventoryValidatorProvider),
  );
});

/// Single source of truth for checkout availability.
///
/// This intentionally does not block on high-demand/fallback states. Orders are
/// blocked only by explicit live Firebase flags, inventory, address, or delivery
/// area validation.
class AvailabilityService {
  AvailabilityService({
    required MaintenanceRepository maintenanceRepository,
    required OrderInventoryValidator inventoryValidator,
    FirebaseFirestore? firestore,
  }) : _maintenanceRepository = maintenanceRepository,
       _inventoryValidator = inventoryValidator,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final MaintenanceRepository _maintenanceRepository;
  final OrderInventoryValidator _inventoryValidator;
  final FirebaseFirestore _firestore;

  Future<bool> canPlaceOrder({
    required List<CartItem> cartItems,
    required AddressModel? address,
    required String pin,
  }) async {
    final result = await check(
      cartItems: cartItems,
      address: address,
      pin: pin,
    );
    return result.canPlaceOrder;
  }

  Future<String?> getBlockingReason({
    required List<CartItem> cartItems,
    required AddressModel? address,
    required String pin,
  }) async {
    final result = await check(
      cartItems: cartItems,
      address: address,
      pin: pin,
    );
    return result.blockingReason;
  }

  Future<AvailabilityResult> check({
    required List<CartItem> cartItems,
    required AddressModel? address,
    required String pin,
  }) async {
    final config = await _maintenanceRepository.fetchConfig();
    final deliveryArea = await _fetchDeliveryArea(pin.trim());
    final inventory = await _inventoryValidator.validateCheckout(cartItems);

    final blockingReason = _blockingReason(
      config: config,
      inventory: inventory,
      deliveryAreaValid: deliveryArea.isValid,
      address: address,
      cartItems: cartItems,
    );

    return AvailabilityResult(
      config: config,
      inventory: inventory,
      deliveryAreaValid: deliveryArea.isValid,
      deliveryCharge: deliveryArea.charge,
      blockingReason: blockingReason,
    );
  }

  String? _blockingReason({
    required MaintenanceConfig config,
    required CheckoutValidationResult inventory,
    required bool deliveryAreaValid,
    required AddressModel? address,
    required List<CartItem> cartItems,
  }) {
    if (config.enabled && config.affectsUserApp) {
      return 'Maintenance mode is active';
    }
    if (!config.userAppEnabled) {
      return 'User app disabled by admin';
    }
    if (!config.storeOpen || !config.legacyStoreActive) {
      return 'Store is closed';
    }
    if (!config.orderingEnabled || !config.allowOrders) {
      return 'Ordering disabled by admin';
    }
    if (!config.driverAppEnabled) {
      return 'Delivery unavailable right now';
    }
    if (address == null ||
        (address.id.trim().isEmpty &&
            address.address.trim().isEmpty &&
            address.area.trim().isEmpty)) {
      return 'Address is required';
    }
    if (cartItems.isEmpty) {
      return 'Your cart is empty';
    }
    if (!deliveryAreaValid) {
      return 'Delivery unavailable in this area';
    }
    return inventory.errorMessage;
  }

  Future<({bool isValid, double charge})> _fetchDeliveryArea(String pin) async {
    if (pin.isEmpty) return (isValid: false, charge: 0.0);
    final snap = await _firestore
        .collection('delivery_zones')
        .where('pin_codes', arrayContains: pin)
        .where('is_active', isEqualTo: true)
        .limit(1)
        .get(const GetOptions(source: Source.server));

    if (snap.docs.isEmpty) return (isValid: false, charge: 0.0);
    final data = snap.docs.first.data();
    return (
      isValid: true,
      charge: (data['delivery_charge'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class AvailabilityResult {
  const AvailabilityResult({
    required this.config,
    required this.inventory,
    required this.deliveryAreaValid,
    required this.deliveryCharge,
    required this.blockingReason,
  });

  final MaintenanceConfig config;
  final CheckoutValidationResult inventory;
  final bool deliveryAreaValid;
  final double deliveryCharge;
  final String? blockingReason;

  bool get canPlaceOrder => blockingReason == null;
  bool get maintenanceMode => config.enabled && config.affectsUserApp;
  bool get orderingEnabled => config.orderingEnabled && config.allowOrders;
  bool get storeOpen => config.storeOpen && config.legacyStoreActive;
  bool get vendorActive => inventory.vendors.every((v) => v.isActive);
  bool get deliveryEnabled => config.driverAppEnabled && deliveryAreaValid;

  void debugLog() {
    final vendor = inventory.firstVendor;
    final product = inventory.firstProduct;

    debugPrint('========== ORDER AVAILABILITY ==========');
    debugPrint('maintenanceMode: $maintenanceMode');
    debugPrint('orderingEnabled: $orderingEnabled');
    debugPrint('storeOpen: $storeOpen');
    debugPrint('vendorActive: $vendorActive');
    debugPrint('deliveryEnabled: $deliveryEnabled');
    debugPrint('userAppEnabled: ${config.userAppEnabled}');
    debugPrint('vendorAppEnabled: ${config.vendorAppEnabled}');
    debugPrint('driverAppEnabled: ${config.driverAppEnabled}');
    debugPrint('deliveryAreaValid: $deliveryAreaValid');
    debugPrint('blockingReason: $blockingReason');
    debugPrint('Vendor Active: ${vendor?.isActive}');
    debugPrint('Vendor Approved: ${vendor?.isApproved}');
    debugPrint('Vendor Open: ${vendor?.isOpen}');
    debugPrint('Product Available: ${product?.isAvailable}');
    debugPrint('Product Stock: ${product?.stock}');
    debugPrint('Validation Error: ${inventory.errorMessage}');

    for (final v in inventory.vendors) {
      debugPrint(
        'Vendor[${v.vendorId}] active=${v.isActive} '
        'approved=${v.isApproved} open=${v.isOpen} '
        'exists=${v.exists} status=${v.status}',
      );
    }
    for (final p in inventory.products) {
      debugPrint(
        'Product[${p.productId}] "${p.name}" available=${p.isAvailable} '
        'stock=${p.stock} requested=${p.requestedQuantity} '
        'vendor=${p.vendorId} exists=${p.exists}',
      );
    }
  }
}
