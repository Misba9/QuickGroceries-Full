import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_assets.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

class DeliveryBoyCard extends StatelessWidget {
  const DeliveryBoyCard({
    Key? key,
    required this.deliveryBoyName,
    required this.orderId,
  }) : super(key: key);
  final String deliveryBoyName;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage(AppAssets.deliveryBoy),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deliveryBoyName,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    color: GlobalVariables.darkGrey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(AppIcons.chat, color: Colors.black),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      shape: BoxShape.circle,
                      color: GlobalVariables.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(9),
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(AppIcons.phone, color: Colors.black),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
