import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/constants/app_icons.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';

class CouponScreen extends ConsumerStatefulWidget {
  const CouponScreen({super.key});

  @override
  ConsumerState<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends ConsumerState<CouponScreen> {
  String? _highlightCode;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final couponsAsync = ref.watch(couponsStreamProvider);

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          'Applied ${cart.coupon!.code} · ${cart.coupon!.discountPercent}% off',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: notifier.removeCoupon,
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: couponsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(child: Text('No coupons right now'));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final meetsMin =
                            cart.bill.subtotal >= c.minOrderValue;
                        final disabled = !meetsMin;

                        return FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: InkWell(
                            onTap: disabled
                                ? null
                                : () => setState(() => _highlightCode = c.code),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              height: width * .22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _highlightCode == c.code
                                      ? Colors.amber
                                      : Colors.grey.shade200,
                                  width: _highlightCode == c.code ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    height: width * .12,
                                    child: Image.asset(AppIcons.coupon),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          c.code,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.description.isEmpty
                                              ? '${c.discountPercent}% OFF'
                                              : c.description,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (c.minOrderValue > 0)
                                          Text(
                                            disabled
                                                ? 'Min order ₹${c.minOrderValue}'
                                                : 'Eligible ✓',
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
                                  Radio<String>(
                                    value: c.code,
                                    groupValue: cart.coupon?.code,
                                    onChanged: disabled
                                        ? null
                                        : (_) => notifier.applyCoupon(
                                              AppliedCoupon(
                                                id: c.id,
                                                code: c.code,
                                                discountPercent:
                                                    c.discountPercent,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Failed to load')),
                ),
              ),
              PrimaryButton(
                label: 'Apply',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
