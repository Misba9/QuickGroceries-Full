import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/product_view/presentation/providers/quantity_provider.dart';

/// Variant chips shown above the cart action bar.
///
/// For vegetables, renders a 250 g / 500 g / 1 kg / 2 kg weight selector
/// that drives [productWeightProvider]. For non-vegetable products, the
/// widget collapses to nothing (the unit chip is shown elsewhere on the
/// detail screen).
class ProductVariantWidget extends ConsumerWidget {
  const ProductVariantWidget({super.key, required this.product});
  final ProductModel product;

  static const List<int> _weightOptions = [250, 500, 1000, 2000];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!product.isVegetable) return const SizedBox.shrink();

    final selected = ref.watch(productWeightProvider(product.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select weight',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppSurface.of(context).text,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weightOptions.map((g) {
              final isSelected = selected == g;
              return _WeightChip(
                label: _format(g),
                price: (product.price * g) / 1000.0,
                slashed: product.hasDiscount
                    ? (product.discountPrice * g) / 1000.0
                    : null,
                selected: isSelected,
                onTap: () => ref
                    .read(productWeightProvider(product.id).notifier)
                    .set(g),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _format(int grams) {
    if (grams >= 1000) {
      final kg = grams / 1000;
      return kg == kg.truncateToDouble()
          ? '${kg.toStringAsFixed(0)} kg'
          : '${kg.toStringAsFixed(1)} kg';
    }
    return '$grams g';
  }
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.label,
    required this.price,
    required this.slashed,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double price;
  final double? slashed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.primary.withValues(alpha: 0.12)
              : surface.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColor.primary : surface.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColor.primary : surface.text,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: surface.text,
                  ),
                ),
                if (slashed != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '₹${slashed!.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: surface.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
