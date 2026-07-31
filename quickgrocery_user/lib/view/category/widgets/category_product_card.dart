import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

class CategoryProductCard extends StatelessWidget {
  const CategoryProductCard({
    super.key,
    required this.image,
    required this.title,
    required this.amount,
    required this.actualAmount,
    required this.quantity,
    required this.onTap,
    required this.isSelected,
    required this.onProductAdd,
    required this.itemCount,
    required this.onQuantityAdd,
    required this.onQuantityRemove,
  });
  final String image;
  final String title;
  final String amount;
  final String actualAmount;
  final String quantity;
  final Function() onTap;
  final bool isSelected;
  final Function() onProductAdd;
  final Function() onQuantityAdd;
  final Function() onQuantityRemove;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(6),
        height: 220,
        width: MediaQuery.of(context).size.width / 2.5,
        decoration: BoxDecoration(color: surface.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2.5,
              height: 120,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: surface.subtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    url: image,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width / 2.5,
                    height: 120,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.favorite_border,
                      color: surface.iconInactive,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.h10,
            Text(
              title,
              style: TextStyle(color: surface.textPrimary),
            ),
            AppSpacing.h5,
            Text(
              quantity,
              style: TextStyle(fontSize: 12, color: surface.textMuted),
            ),
            AppSpacing.h5,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          "₹$amount",
                          style: TextStyle(color: surface.textPrimary),
                        ),
                        Text(
                          "₹$actualAmount",
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: surface.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.h5,
            isSelected
                ? Row(
                    children: [
                      IconButton(
                        onPressed: onQuantityRemove,
                        icon: Icon(Icons.remove, color: surface.iconActive),
                      ),
                      Text(
                        itemCount.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: surface.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: onQuantityAdd,
                        icon: Icon(Icons.add, color: surface.iconActive),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: onProductAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
