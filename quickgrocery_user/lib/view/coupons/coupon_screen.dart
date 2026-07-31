import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/constants/app_icons.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/device/device_id_service.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/core/loading/loading.dart';

class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key, this.checkoutPhone});

  /// Phone from checkout address for first-order validation.
  final String? checkoutPhone;

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  final _manualCode = TextEditingController();
  String? _highlightCode;
  bool _applying = false;

  @override
  void dispose() {
    _manualCode.dispose();
    super.dispose();
  }

  Future<void> _applyCode(String code) async {
    if (_applying || code.trim().isEmpty) return;
    setState(() => _applying = true);
    final deviceId = await DeviceIdService.getOrCreate();
    final err = await ref.read(cartProvider.notifier).applyCouponValidated(
          code: code,
          validationClient: ref.read(couponValidationClientProvider),
          phone: widget.checkoutPhone,
          deviceId: deviceId,
        );
    if (!mounted) return;
    setState(() => _applying = false);
    if (err != null) {
      AppSnackBar.error(err, context: context);
      return;
    }
    AppSnackBar.success(context.l10n.couponAppliedSuccess, context: context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final couponsAsync = ref.watch(couponsStreamProvider);
    final subtotal = cart.bill.subtotal > 0
        ? cart.bill.subtotal
        : cart.items.fold(0.0, (a, i) => a + i.lineTotal);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.couponsAndOffers)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cart.coupon != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cart.coupon!.isFirstOrderOffer
                              ? 'First Order Offer · ${cart.coupon!.code}'
                              : 'Applied ${cart.coupon!.code}',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: notifier.removeCoupon,
                        child: Text(context.l10n.remove),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCode,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _applying
                        ? null
                        : () => _applyCode(_manualCode.text),
                    child: _applying
                        ? const SizedBox(width: 20, height: 20, child: AppLoading.micro)
                        : Text(context.l10n.apply),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: couponsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Center(child: Text(context.l10n.noCouponsRightNow));
                    }

                    final sorted = [...list]
                      ..sort((a, b) {
                        if (a.isFirstOrderOffer && !b.isFirstOrderOffer) {
                          return -1;
                        }
                        if (!a.isFirstOrderOffer && b.isFirstOrderOffer) {
                          return 1;
                        }
                        return 0;
                      });

                    final firstOrder = sorted
                        .where((c) => c.isFirstOrderOffer)
                        .toList();
                    final others =
                        sorted.where((c) => !c.isFirstOrderOffer).toList();

                    return ListView(
                      children: [
                        if (firstOrder.isNotEmpty) ...[
                          SectionHeader(
                            title: 'First Order Offer',
                            icon: Icons.celebration_outlined,
                            compact: true,
                          ),
                          ...firstOrder.map(
                            (c) => _CouponTile(
                              coupon: c,
                              subtotal: subtotal,
                              highlightCode: _highlightCode,
                              applying: _applying,
                              onTap: () => _applyCode(c.code),
                              onSelect: () =>
                                  setState(() => _highlightCode = c.code),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (others.isNotEmpty) ...[
                          const SectionHeader(
                            title: 'More offers',
                            icon: Icons.local_offer_outlined,
                            compact: true,
                          ),
                          ...others.map(
                            (c) => _CouponTile(
                              coupon: c,
                              subtotal: subtotal,
                              highlightCode: _highlightCode,
                              applying: _applying,
                              onTap: () => _applyCode(c.code),
                              onSelect: () =>
                                  setState(() => _highlightCode = c.code),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      AppLoading.center,
                  error: (_, __) =>
                      Center(child: Text(context.l10n.could_not_load_coupons)),
                ),
              ),
              PrimaryButton(
                label: 'Done',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.subtotal,
    required this.highlightCode,
    required this.applying,
    required this.onTap,
    required this.onSelect,
  });

  final CouponEntry coupon;
  final double subtotal;
  final String? highlightCode;
  final bool applying;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final meetsMin = subtotal >= coupon.minOrderValue;
    final disabled = !meetsMin || applying;
    final isFirst = coupon.isFirstOrderOffer;
    final surface = AppSurface.of(context);

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: disabled ? onSelect : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFirst
                ? surface.secondaryOrange.withValues(alpha: 0.12)
                : surface.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlightCode == coupon.code
                  ? AppColor.primary
                  : isFirst
                      ? surface.secondaryOrange.withValues(alpha: 0.45)
                      : surface.border,
              width: highlightCode == coupon.code ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                height: width * .1,
                child: Image.asset(AppIcons.coupon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          coupon.code,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: surface.textPrimary,
                          ),
                        ),
                        if (isFirst) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: surface.offerBadge,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '1st ORDER',
                              style: TextStyle(
                                color: surface.onWarning,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coupon.displaySubtitle,
                      style: TextStyle(
                        color: surface.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (coupon.minOrderValue > 0)
                      Text(
                        disabled
                            ? 'Min order ₹${coupon.minOrderValue}'
                            : 'Eligible · Tap to apply',
                        style: TextStyle(
                          color: disabled
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: disabled ? Colors.grey : Colors.green.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
