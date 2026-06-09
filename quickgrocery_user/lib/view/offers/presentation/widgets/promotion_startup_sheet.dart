import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';
import 'package:quickgrocery/view/offers/presentation/utils/offer_navigation.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_promo_video_card.dart';

/// Half-screen bottom sheet with blur barrier — promotional video + CTA.
Future<void> showPromotionStartupSheet({
  required BuildContext context,
  required WidgetRef ref,
  required OfferBannerModel offer,
  required int autoCloseSeconds,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: AppMotion.medium,
    pageBuilder: (ctx, anim, _) {
      return _PromotionStartupDialogBody(
        animation: anim,
        offer: offer,
        autoCloseSeconds: autoCloseSeconds,
        ref: ref,
      );
    },
  );
}

class _PromotionStartupDialogBody extends StatefulWidget {
  const _PromotionStartupDialogBody({
    required this.animation,
    required this.offer,
    required this.autoCloseSeconds,
    required this.ref,
  });

  final Animation<double> animation;
  final OfferBannerModel offer;
  final int autoCloseSeconds;
  final WidgetRef ref;

  @override
  State<_PromotionStartupDialogBody> createState() =>
      _PromotionStartupDialogBodyState();
}

class _PromotionStartupDialogBodyState extends State<_PromotionStartupDialogBody> {
  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.acquire();
    final secs = widget.autoCloseSeconds.clamp(3, 120);
    Future<void>.delayed(Duration(seconds: secs), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    FloatingCartSuppression.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Limited offer',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppSurface.textSecondary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: (widget.offer.bannerHeightPx ?? 180)
                              .clamp(140.0, 240.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: OfferPromoVideoCard(
                              offer: widget.offer,
                              trackViewOnInit: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Consumer(
                          builder: (context, ref, _) {
                            final pricing =
                                ref.watch(pricingConfigProvider).valueOrNull;
                            if (pricing == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: 0.08),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.md),
                                  border: Border.all(
                                    color: AppColor.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  DeliveryPricingPolicy.startupFooterLine(
                                    pricing,
                                  ),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppSurface.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Pulse(
                          infinite: true,
                          duration: const Duration(milliseconds: 1400),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await navigateFromOffer(
                                context,
                                widget.ref,
                                widget.offer,
                              );
                            },
                            child: Text(
                              widget.offer.ctaText.isEmpty
                                  ? 'Shop now'
                                  : widget.offer.ctaText,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
