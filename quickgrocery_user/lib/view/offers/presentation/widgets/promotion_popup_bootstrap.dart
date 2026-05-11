import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_startup_sheet.dart';

const String _kPromotionPopupLastShownMs = 'promotion_popup_last_shown_ms';

/// Shows the promotional bottom sheet once eligible data loads (after splash /
/// permissions), respecting admin frequency rules.
class PromotionPopupBootstrap extends ConsumerStatefulWidget {
  const PromotionPopupBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PromotionPopupBootstrap> createState() =>
      _PromotionPopupBootstrapState();
}

class _PromotionPopupBootstrapState extends ConsumerState<PromotionPopupBootstrap> {
  bool _attempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAttempts());
  }

  Future<void> _scheduleAttempts() async {
    if (_attempted) return;
    for (var i = 0; i < 12; i++) {
      if (!mounted) return;
      final done = await _tryShowPopup();
      if (done) {
        _attempted = true;
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: 280 + i * 40));
    }
    _attempted = true;
  }

  /// Returns true when we should stop retrying (shown, disabled, throttled, or empty).
  Future<bool> _tryShowPopup() async {
    final settings = ref.read(promotionPopupSettingsProvider).valueOrNull;
    if (settings == null) return false;

    if (!settings.enabled) return true;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kPromotionPopupLastShownMs) ?? 0;
    if (lastMs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final gap = Duration(hours: settings.frequencyHours);
      if (DateTime.now().difference(last) < gap) return true;
    }

    final offers = ref.read(popupEligibleOffersProvider).valueOrNull;
    if (offers == null) return false;
    if (offers.isEmpty) return true;

    OfferBannerModel? pick;
    final pinned = settings.pinnedOfferId.trim();
    if (pinned.isNotEmpty) {
      for (final o in offers) {
        if (o.id == pinned) {
          pick = o;
          break;
        }
      }
    }
    pick ??= offers.first;

    await prefs.setInt(
      _kPromotionPopupLastShownMs,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (!mounted) return true;

    await showPromotionStartupSheet(
      context: context,
      ref: ref,
      offer: pick,
      autoCloseSeconds:
          pick.popupAutoCloseSeconds ?? settings.autoCloseSeconds,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
