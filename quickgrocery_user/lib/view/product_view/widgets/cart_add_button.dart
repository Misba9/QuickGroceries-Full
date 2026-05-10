import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';

class CartAddButton extends StatelessWidget {
  const CartAddButton({
    super.key,
    required this.itemCount,
    required this.onIncrese,
    required this.onDecrece,
    required this.amount,
    required this.addCartclick,
  });
  final String itemCount;
  final Function() onIncrese;
  final Function() onDecrece;
  final Function() addCartclick;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      height: 100,
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onDecrece,
                  child: const Icon(Icons.remove, color: Colors.grey),
                ),
                AppSpacing.w10,
                Text(
                  itemCount,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                AppSpacing.w10,
                GestureDetector(
                  onTap: onIncrese,
                  child: const Icon(Icons.add, color: AppColor.primary),
                ),
              ],
            ),
          ),
          AppSpacing.w20,
          Expanded(
            child: GestureDetector(
              onTap: addCartclick,
              child: Container(
                height: 49,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColor.primary,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buy now',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: VerticalDivider(color: Colors.grey.shade100),
                    ),
                    Text(
                      '₹$amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
