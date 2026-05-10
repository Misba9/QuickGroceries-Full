import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/order_bill/widgets/dual_button.dart';
import 'package:quick_grocery_delivery/features/order_bill/widgets/table_tile.dart';

class OrderBillScreen extends StatelessWidget {
  const OrderBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                GlobalVariables.verticalSpace,
                const Text(
                  'Weldone!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GlobalVariables.verticalSpace,
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Thanks for the delivery. You,ve earned some cash for this delivery. Summary of delivery is detailed below. Would you like to continue?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: GlobalVariables.darkGrey),
                  ),
                ),
                GlobalVariables.verticalSpace,
                GlobalVariables.verticalSpace,
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: const [
                      TableTile(title: 'Total', value: '250', isTitle: true),
                      Divider(),
                      TableTile(
                        title: 'Product quantity',
                        value: '2',
                        isTitle: false,
                      ),
                      Divider(),
                      TableTile(
                        title: 'Your reward',
                        value: '50',
                        isTitle: false,
                      ),
                      Divider(),
                      TableTile(
                        title: 'Payment method',
                        value: 'Cash on delivery',
                        isTitle: false,
                      ),
                    ],
                  ),
                ),
                GlobalVariables.verticalSpace,
                GlobalVariables.verticalSpace,
                DualButton(width: width, onTap: () {}, onTap2: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
