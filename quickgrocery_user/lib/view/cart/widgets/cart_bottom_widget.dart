import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/cart/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

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
                      AppSnackBar.error(
                        'Sorry!. We are taking Delivery Orders above ₹${p.minumOrder}',
                        context: context,
                      );
                    } else {
                      Navigator.push(context, AppPageRoutes.checkout());
                    }
                  },
                  child: Row(
                    children: [
                      Text(
                        context.l10n.place_order,
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
