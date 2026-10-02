import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/ai_chat/models/ai_chat_models.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

class AiChatProductRail extends StatelessWidget {
  const AiChatProductRail({
    super.key,
    required this.productIds,
    required this.onOpen,
  });

  final List<String> productIds;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AiChatProductCard>>(
      future: AiChatProductCard.fetchByIds(productIds),
      builder: (context, snap) {
        final cards = snap.data ?? const <AiChatProductCard>[];
        if (snap.connectionState == ConnectionState.waiting && cards.isEmpty) {
          return SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 36),
              itemCount: productIds.length.clamp(1, 3),
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => Container(
                width: 132,
                decoration: BoxDecoration(
                  color: AppSurface.of(context).subtle,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        }
        if (cards.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 36, right: 8),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final p = cards[i];
              return _ProductMiniCard(product: p, onOpen: () => onOpen(p.id));
            },
          ),
        );
      },
    );
  }
}

class _ProductMiniCard extends StatelessWidget {
  const _ProductMiniCard({required this.product, required this.onOpen});

  final AiChatProductCard product;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final price = product.hasOffer ? product.discountPrice : product.price;
    return Material(
      color: surface.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: surface.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ColoredBox(
                    color: surface.subtle,
                    child: product.image.isEmpty
                        ? const Center(child: Icon(Icons.image_outlined))
                        : CachedImage(url: product.image, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '₹${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: surface.textPrimary,
                    ),
                  ),
                  if (product.hasOffer) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                          color: surface.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                product.inStock ? 'In stock' : 'Out of stock',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: product.inStock
                      ? surface.success
                      : surface.danger,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColor.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
