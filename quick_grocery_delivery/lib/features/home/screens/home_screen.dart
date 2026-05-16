import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quick_grocery_delivery/constants/app_spacing.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/chat/screens/chat_screen.dart';
import 'package:quick_grocery_delivery/features/home/pages/home_page.dart';
import 'package:quick_grocery_delivery/features/orders/screens/order_screen.dart';
import 'package:quick_grocery_delivery/features/payment/screens/payment_screen.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/main.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List pages = const [HomePage(), OrderScreen(), PaymentScreen()];
  List bottomItems = [AppIcons.home, AppIcons.bag, AppIcons.wallet];

  int _selectIndex = 0;

  @override
  void initState() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        // flutterLocalNotificationsPlugin.show(
        //   notification.hashCode,
        //   notification.title,
        //   notification.body,
        //   NotificationDetails(
        //     android: AndroidNotificationDetails(
        //       channel.id,
        //       channel.name,
        //       channelDescription: channel.description,
        //       importance: Importance.high,
        //       color: Colors.blue,
        //       playSound: true,
        //       icon: '@mipmap/ic_launcher',
        //     ),
        //   ),
        // );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: Text(notification.title.toString()),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(notification.body.toString())],
                ),
              ),
            );
          },
        );
      }
    });
    Provider.of<OrderService>(context, listen: false).getDeliveryBoy();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return provider.deliveryBoy == null
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : provider.deliveryBoy!.isActive
        ? Scaffold(
            bottomNavigationBar: Container(
              height: height * .10,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Center(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bottomItems.length,
                  shrinkWrap: true,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectIndex = i;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          bottomItems[i],
                          color: _selectIndex == i
                              ? GlobalVariables.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            body: pages[_selectIndex],
          )
        : Scaffold(
            body: Column(
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2.5,
                      ),
                      SizedBox(
                        height: 100,
                        child: Image.asset('assets/icons/disable.png'),
                      ),
                      AppSpacing.h20,
                      const Text(
                        'Your Account Has been Disabled',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      AppSpacing.h10,
                      const Text(
                        'Please contact support',
                        style: TextStyle(),
                      ),
                      AppSpacing.h15,
                      ElevatedButton.icon(
                        onPressed: () => SupportContactSheet.show(context),
                        icon: const Icon(Icons.support_agent_outlined),
                        label: const Text('Contact Support'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({Key? key, required this.title, required this.onTap})
    : super(key: key);
  final String title;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.black, fontSize: 16)),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'View All',
            style: TextStyle(fontSize: 16, color: GlobalVariables.darkGrey),
          ),
        ),
      ],
    );
  }
}

// class OrderCard extends StatelessWidget {
//   const OrderCard({
//     Key? key,
//     required this.width,
//   }) : super(key: key);

//   final double width;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 10),
//       padding: const EdgeInsets.all(15),
//       width: width,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text(
//                 'Order #3121323',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(
//                 width: 20,
//               ),
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                     color: GlobalVariables.secondary.withOpacity(0.6),
//                     borderRadius: BorderRadius.circular(10)),
//                 child: const Center(
//                   child: Text('4.0km'),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(
//             height: 10,
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       SizedBox(
//                         height: width * .04,
//                         child: Image.asset(AppIcons.food),
//                       ),
//                       const SizedBox(
//                         width: 10,
//                       ),
//                       const Text(
//                         'malappuram, kerala, india',
//                         style: TextStyle(
//                             color: GlobalVariables.darkGrey, fontSize: 15),
//                       )
//                     ],
//                   ),
//                   const SizedBox(
//                     height: 10,
//                   ),
//                   Row(
//                     children: [
//                       SizedBox(
//                         height: width * .04,
//                         child: Image.asset(AppIcons.home),
//                       ),
//                       const SizedBox(
//                         width: 10,
//                       ),
//                       const Text(
//                         'kondotty, kerala, india',
//                         style: TextStyle(
//                             color: GlobalVariables.darkGrey, fontSize: 15),
//                       )
//                     ],
//                   ),
//                 ],
//               ),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const TrackingScreen()));
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.black, width: 1),
//                   ),
//                   height: width * .10,
//                   width: width * .22,
//                   child: const Center(
//                     child: Text('Start'),
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

class LeadingCard extends StatelessWidget {
  const LeadingCard({
    Key? key,
    required this.width,
    required this.title,
    required this.value,
  }) : super(key: key);

  final double width;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        height: width * .30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            GlobalVariables.verticalSpace,
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanPay extends StatelessWidget {
  const ScanPay({Key? key, required this.width}) : super(key: key);

  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/qr.png'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        height: width * .15,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scan and Pay',
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(
              height: width * .07,
              width: width * .07,
              child: Image.asset(AppIcons.scan),
            ),
          ],
        ),
      ),
    );
  }
}
