import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Premium horizontal combo offer card.
class ComboOfferCard extends StatelessWidget {
  const ComboOfferCard({
    super.key,
    required this.combo,
    required this.onTap,
    required this.onAdd,
    this.compact = false,
  });

  final ComboOfferModel combo;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppSurface.of(context).card,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      elevation: 0,
      shadowColor: AppSurface.of(context).shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppSurface.of(context).border),
            boxShadow: AppShadow.cardOf(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                child: AspectRatio(
                  aspectRatio: compact ? 2.4 : 2.1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      combo.image.isNotEmpty
                          ? CachedImage(
                              url: combo.image,
                              fit: BoxFit.cover,
                              memCacheWidth: (w * 2).round(),
                            )
                          : _ProductCollage(combo: combo),
                      if (combo.discountPercent > 0)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _Badge(
                            '${combo.discountPercent}% OFF',
                            AppColor.primary,
                          ),
                        ),
                      if (combo.isFlashSale && combo.timeRemaining != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _Badge(
                            _formatTimer(combo.timeRemaining!),
                            Colors.red.shade600,
                            textColor: Colors.white,
                          ),
                        ),
                      if (combo.hasLimitedStock)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: _Badge(
                            'Only ${combo.stock} left',
                            Colors.black87,
                            textColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      combo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 16,
                        height: 1.2,
                      ),
                    ),
                    if (combo.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        combo.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppSurface.of(context).textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: 8),
                    _IncludedPreview(combo: combo),
                    if (combo.vendorName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        combo.vendorName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppSurface.of(context).textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          fmt.format(combo.originalTotalPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppSurface.of(context).textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          fmt.format(combo.comboPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppSurface.of(context).textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Save ${fmt.format(combo.savingsAmount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF11A04C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: const Color(0xFF1A1A1A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        onPressed: combo.isAvailableNow ? onAdd : null,
                        child: Text(
                          combo.isAvailableNow ? 'Add combo' : 'Unavailable',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimer(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return '${d.inSeconds}s';
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.bg, {this.textColor = const Color(0xFF1A1A1A)});
  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _ProductCollage extends StatelessWidget {
  const _ProductCollage({required this.combo});
  final ComboOfferModel combo;

  @override
  Widget build(BuildContext context) {
    final imgs = combo.products
        .map((p) => p.image)
        .where((u) => u.isNotEmpty)
        .take(3)
        .toList();
    if (imgs.isEmpty) {
      return Container(
        color: AppSurface.of(context).subtle,
        child: const Icon(Icons.shopping_basket_outlined, size: 48),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < imgs.length; i++)
          Expanded(
            child: CachedImage(url: imgs[i], fit: BoxFit.cover),
          ),
      ],
    );
  }
}

class _IncludedPreview extends StatelessWidget {
  const _IncludedPreview({required this.combo});
  final ComboOfferModel combo;

  @override
  Widget build(BuildContext context) {
    final names = combo.products.isNotEmpty
        ? combo.products.map((p) => p.name).where((n) => n.isNotEmpty)
        : combo.productIds.map((_) => 'Item');
    final text = names.take(3).join(' · ');
    final extra = combo.productIds.length > 3
        ? ' +${combo.productIds.length - 3} more'
        : '';

    return Text(
      '$text$extra',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: 11.5,
        color: AppSurface.of(context).textSecondary,
        height: 1.3,
      ),
    );
  }
}
