import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/delivery_boy_card.dart';
import 'package:quick_grocery_delivery/features/order_confirmation/widgets/duration_card.dart';
import 'package:quick_grocery_delivery/widgets/scrollable_bottom_panel.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: const GoogleMap(
        myLocationButtonEnabled: false,
        initialCameraPosition: CameraPosition(
          target: LatLng(11.6988, 75.5466),
          zoom: 15.5,
        ),
      ),
      bottomNavigationBar: ScrollableBottomPanel(
        maxHeightFraction: 0.42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                height: 5,
                width: width * .20,
                decoration: BoxDecoration(
                  color: const Color(0xFF393939),
                  borderRadius: BorderRadius.circular(10),
                ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    'Go to Restaurant',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
