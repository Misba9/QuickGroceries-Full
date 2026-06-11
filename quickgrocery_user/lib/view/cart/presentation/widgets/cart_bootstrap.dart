import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/startup/app_startup_log.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';

import '../providers/cart_bootstrap_state.dart';
import '../providers/cart_notifier.dart';
import 'cart_inventory_listener.dart';

/// Bridges Riverpod's [CartNotifier] with the legacy `package:provider`
/// services it needs to talk to:
///
///   • `CategoryService`   — bidirectional cart bridge.
///   • `DeliveryZoneService` — read by [zoneDeliveryProvider].
///
/// Place once **below** `MultiProvider` (e.g., wrapping `MaterialApp.home`).
class CartBootstrap extends ConsumerStatefulWidget {
  const CartBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CartBootstrap> createState() => _CartBootstrapState();
}

class _CartBootstrapState extends ConsumerState<CartBootstrap> {
  bool _attachScheduled = false;
  int _attachAttempts = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAttach();
  }

  void _scheduleAttach() {
    if (_attachScheduled) return;
    _attachScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _tryAttach());
  }

  Future<void> _tryAttach() async {
    if (!mounted) return;
    if (ref.read(cartBootstrapReadyProvider)) return;
    _attachAttempts++;
    try {
      final legacy =
          legacy_provider.Provider.of<CategoryService>(context, listen: false);
      ref.read(cartProvider);
      ref.read(cartProvider.notifier).attachLegacy(legacy);

      final zoneService = legacy_provider.Provider.of<DeliveryZoneService>(
        context,
        listen: false,
      );
      ref.read(deliveryZoneServiceProvider.notifier).state = zoneService;
      ref.invalidate(zoneDeliveryProvider);

      ref.read(cartBootstrapReadyProvider.notifier).state = true;
      AppStartupLog.log(
        'cart bootstrap ready',
        'attempt=$_attachAttempts uid=${ref.read(cartProvider).items.length} lines',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('CartBootstrap attach failed (attempt $_attachAttempts): $e\n$st');
      }
      _attachScheduled = false;
      if (_attachAttempts < 5 && mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _tryAttach());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(cartBootstrapReadyProvider, (previous, next) {
      if (next == false && previous == true) {
        _attachScheduled = false;
        _attachAttempts = 0;
        final isGuest = ref.read(guestSessionProvider);
        if (FirebaseAuth.instance.currentUser != null || isGuest) {
          _scheduleAttach();
        }
      }
    });

    return CartInventoryListener(child: widget.child);
  }
}
