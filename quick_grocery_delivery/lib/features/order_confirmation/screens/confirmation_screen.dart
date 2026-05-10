import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/delivery_boy_card.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/duration_card.dart';

class OrderConfirmationScreeen extends StatelessWidget {
  const OrderConfirmationScreeen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        height: height * .60,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.black,
        ),
        child: Column(
          children: [
            Container(
              height: 5,
              width: width * .20,
              decoration: BoxDecoration(
                color: const Color(0xFF393939),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            const DeliveryBoyCard(
              deliveryBoyName: 'Hashim M',
              orderId: '08276253524',
            ),
            const SizedBox(height: 10),
            const Divider(color: GlobalVariables.darkGrey),
            const SizedBox(height: 10),
            const TimeRangeCard(
              time: '10:20 AM',
              duration: '30 min',
              distance: '2.5 km',
            ),
            const SizedBox(height: 10),
            const Divider(color: GlobalVariables.darkGrey),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: Image.asset(AppIcons.food),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'Pickup Address',
                          style: TextStyle(
                            color: GlobalVariables.darkGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Malappuram, kerala, india',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    GlobalVariables.verticalSpace,
                    Row(
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: Image.asset(AppIcons.home),
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            color: GlobalVariables.darkGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'kondotty, kerala, india',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
                const Text(
                  'Planet Cafe',
                  style: TextStyle(
                    color: GlobalVariables.darkGrey,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: GlobalVariables.darkGrey),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Payment Method',
                  style: TextStyle(
                    color: GlobalVariables.darkGrey,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: GlobalVariables.darkGrey),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: width * .13,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                      border: Border.all(width: 2, color: Colors.red),
                    ),
                    child: const Center(
                      child: Text(
                        'Decline',
                        style: TextStyle(color: Colors.red, fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: width * .13,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: const Center(
                      child: Text(
                        'Confirm',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: const GoogleMap(
        myLocationButtonEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(11.6988, 75.5466),
          zoom: 15.5,
        ),
      ),
    );
  }
}
