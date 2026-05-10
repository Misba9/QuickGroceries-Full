import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/delivery_boy_card.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/duration_card.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: const GoogleMap(
        myLocationButtonEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(11.6988, 75.5466),
          zoom: 15.5,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        height: height * .35,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Colors.black,
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 5,
              width: width * .20,
              decoration: BoxDecoration(
                color: const Color(0xFF393939),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            GlobalVariables.verticalSpace,
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
            Container(
              height: height * .06,
              width: width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: const Center(
                child: Text('Go to Restaurant', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
