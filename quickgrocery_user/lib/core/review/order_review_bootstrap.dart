import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/review/review_service.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';

/// Listens for delivered orders + app resume and schedules the review prompt.
///
/// Place under [LandingScreen] (next to [PromotionPopupBootstrap]) so it only
/// runs once the user reaches home after splash / auth.
class OrderReviewBootstrap extends ConsumerStatefulWidget {
  const OrderReviewBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OrderReviewBootstrap> createState() =>
      _OrderReviewBootstrapState();
}

class _OrderReviewBootstrapState extends ConsumerState<OrderReviewBootstrap>
    with WidgetsBindingObserver {
  bool _attemptedThisSession = false;
  DateTime? _lastResumeCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_tryPrompt(fromResume: false));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final now = DateTime.now();
    if (_lastResumeCheck != null &&
        now.difference(_lastResumeCheck!) < const Duration(minutes: 2)) {
      return;
    }
    _lastResumeCheck = now;
    // Allow another attempt after resume (e.g. delivered while backgrounded).
    _attemptedThisSession = false;
    unawaited(_tryPrompt(fromResume: true));
  }

  Future<void> _tryPrompt({required bool fromResume}) async {
    if (!mounted || _attemptedThisSession) return;
    if (!ref.read(appBootstrapCompleteProvider)) return;

    final top = appRouteObserver.topRouteName;
    if (top == AppRoutes.otp ||
        top == AppRoutes.login ||
        top == AppRoutes.payment ||
        top == AppRoutes.checkout) {
      return;
    }

    final svc = await OrderReviewService.instance();
    if (!mounted) return;

    await svc.flushPendingIfSafe(context);
    if (!mounted) return;

    final ordersAsync = ref.read(ordersStreamProvider);
    final orders = ordersAsync.valueOrNull;
    if (orders == null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null || uid.isEmpty) return;

    // Eligibility is primarily local prefs (once per order / Later / No Thanks).
    final candidates = orders.delivered
        .where((o) => o.isDelivered)
        .map((o) => (orderId: o.id, userId: o.uuid.isNotEmpty ? o.uuid : uid))
        .toList();

    if (candidates.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[OrderReview] bootstrap — no delivered orders (resume=$fromResume)',
        );
      }
      _attemptedThisSession = true;
      return;
    }

    // Mark before awaiting so we don't stack dialogs from rebuilds.
    _attemptedThisSession = true;
    await svc.maybePromptForDeliveredOrders(
      context: context,
      candidates: candidates,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appBootstrapCompleteProvider, (prev, next) {
      if (next == true) {
        _attemptedThisSession = false;
        unawaited(_tryPrompt(fromResume: false));
      }
    });

    // When order buckets first load (or a new delivery lands), retry once.
    ref.listen(ordersStreamProvider, (prev, next) {
      next.whenData((orders) {
        if (orders.delivered.isEmpty) return;
        if (_attemptedThisSession) return;
        unawaited(_tryPrompt(fromResume: false));
      });
    });

    return widget.child;
  }
}
