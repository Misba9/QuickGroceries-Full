import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/cart/services/cart_service.dart';
import 'package:quickgrocery/view/cart/presentation/screens/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartBottomBarWidget extends StatelessWidget {
  const CartBottomBarWidget({super.key, required this.amount});
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 80,
      width: MediaQuery.of(context).size.width,
      child: Container(
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColor.primary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "₹$amount",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const VerticalDivider(color: Colors.white),
                ),
              ],
            ),
            Consumer<CartService>(
              builder: (context, p, _) {
                return GestureDetector(
                  onTap: () {
                    if (double.parse(amount) < p.minumOrder) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sorry!. We are taking Delivery Orders above ₹${p.minumOrder}',
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        'place_order'.tr(),
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
