import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';

import '../providers/cart_notifier.dart';
import 'cart_inventory_listener.dart';

/// Bridges Riverpod's [CartNotifier] with the legacy `package:provider`
/// services it needs to talk to:
///
///   • `CategoryService`   — bidirectional cart bridge.
///   • `DeliveryZoneService` — read by [zoneDeliveryProvider].
///
/// Place once **below** `MultiProvider` (e.g., wrapping `MaterialApp.home`).
///
/// Implementation notes:
///   - The attach is performed in [didChangeDependencies] (legal access to
///     inherited providers) but the actual `ref.read(...)` calls are
///     wrapped in [WidgetsBinding.addPostFrameCallback] so the cart
///     notifier's [build] has already returned before any of its public
///     methods are invoked. This is what avoids the
///     "Tried to read the state of an uninitialized provider" error in
///     edge cases where the bootstrap mounts before the very first frame.
///   - `[_attached]` makes the wiring idempotent across rebuilds.
class CartBootstrap extends ConsumerStatefulWidget {
  const CartBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CartBootstrap> createState() => _CartBootstrapState();
}

class _CartBootstrapState extends ConsumerState<CartBootstrap> {
  bool _attached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    _attached = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // Bridge legacy CategoryService.
        final legacy =
            legacy_provider.Provider.of<CategoryService>(context, listen: false);
        // Materialize the cart notifier (runs build → schedules its own
        // post-frame initialization).
        ref.read(cartProvider);
        ref.read(cartProvider.notifier).attachLegacy(legacy);

        // Bridge legacy DeliveryZoneService → Riverpod.
        final zoneService = legacy_provider.Provider.of<DeliveryZoneService>(
          context,
          listen: false,
        );
        ref.read(deliveryZoneServiceProvider.notifier).state = zoneService;
        // Zone lookups were returning 0 until the legacy service existed.
        ref.invalidate(zoneDeliveryProvider);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('CartBootstrap attach failed: $e\n$st');
        }
        // Not fatal — the cart still works in-memory; the bridge will
        // try again on next dependency change.
        _attached = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CartInventoryListener(child: widget.child);
  }
}
