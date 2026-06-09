import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/promotion_startup_sheet.dart';

const String _kPromotionPopupLastShownMs = 'promotion_popup_last_shown_ms';

/// Shows the promotional bottom sheet once bootstrap + offer data are ready.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAttempt());
  }

  void _scheduleAttempt() {
    if (_attempted || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryShowPopup());
  }

  Future<void> _tryShowPopup() async {
    if (_attempted || !mounted) return;
    if (!ref.read(appBootstrapCompleteProvider)) return;

    final settings = ref.read(promotionPopupSettingsProvider).valueOrNull;
    if (settings == null) return;

    if (!settings.enabled) {
      _attempted = true;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_kPromotionPopupLastShownMs) ?? 0;
    if (lastMs > 0) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final gap = Duration(hours: settings.frequencyHours);
      if (DateTime.now().difference(last) < gap) {
        _attempted = true;
        return;
      }
    }

    final offers = ref.read(popupEligibleOffersProvider).valueOrNull;
    if (offers == null) return;
    if (offers.isEmpty) {
      _attempted = true;
      return;
    }

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

    if (!mounted) return;
    _attempted = true;

    await showPromotionStartupSheet(
      context: context,
      ref: ref,
      offer: pick,
      autoCloseSeconds:
          pick.popupAutoCloseSeconds ?? settings.autoCloseSeconds,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(appBootstrapCompleteProvider, (prev, next) {
      if (next) _scheduleAttempt();
    });
    ref.listen(promotionPopupSettingsProvider, (prev, next) {
      if (next.hasValue) _scheduleAttempt();
    });
    ref.listen(popupEligibleOffersProvider, (prev, next) {
      if (next.hasValue) _scheduleAttempt();
    });

    return widget.child;
  }
}
