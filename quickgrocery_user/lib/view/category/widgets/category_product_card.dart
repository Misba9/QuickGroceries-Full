import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(6),
        height: 220,
        width: MediaQuery.of(context).size.width / 2.5,
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width / 2.5,
              height: 120,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(child: Image.network(image)),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.h10,
            Text(title),
            AppSpacing.h5,
            Text(
              quantity,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            AppSpacing.h5,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Text("₹$amount"),
                        Text(
                          "₹$actualAmount",
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
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
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        itemCount.toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        onPressed: onQuantityAdd,
                        icon: const Icon(Icons.add),
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
