import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/models/delivery_boy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService extends ChangeNotifier {
  List<OrderModel>? orders;
  List<OrderModel> newOrders = [];
  List<OrderModel> myTransistOrders = [];
  List<OrderModel> myAcceptedOrders = [];
  List<OrderModel> myPickedOrders = [];
  List<OrderModel> myCancelledOrders = [];
  List<OrderModel> myCompletedOrders = [];
  List<OrderModel> totalOrders = [];
  OrderModel? selectedOrder;
  String orderStatus = '';
  DeliveryBoyModel? deliveryBoy;
  bool profileLoadFailed = false;
  TextEditingController priceController = TextEditingController();

  void onSelectOrder(OrderModel order) async {
    selectedOrder = order;
    orderStatus = order.orderStatus;
    notifyListeners();
  }

  Future<void> updateAdminFcmToken() async {
    try {
      final pref = await SharedPreferences.getInstance();
      String uid = pref.getString('deliveryBoyId') ?? "";
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('delivery_boys')
            .doc(uid)
            .set({'fcm_token': token}, SetOptions(merge: true));

        print('FCM token updated successfully: $token');
      } else {
        print('Failed to get FCM token.');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "siswar-bazar",
      "private_key_id": "22eae8f571ab96e800045b148c307829e7f42dbf",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDO5j4l7Jz6n9yG\nmQNpVzY9Gaxk9U0mV7fKhmsW3C/jlL6PLoqcaSNBjhErZsQIU2Th/nomGx9hpeSd\n9r3dAcsLxUMoR+HFy7OgFRIOZV4aFZdns3v+Q2X+/KUR3v/9/7AoPCWulsbzG2vu\nMhYq4sJl78lPVfeHWVYIj0XSa0/KSKzWZwpWn1v+JwyAAHyFHND80IgjkvW0HgRz\nG7YVTk4cOawbQMY2Z8RR6P5cEKa1z1jUygtbrIzPG/J6lRGNRoqR8WDM+lEjmR6b\n6amc/vWWTAbfZnAlTX6PZLlYSW4AY/lTls1tgJYHIjMm75vZAYarn85InQKrLe32\n6642XFL/AgMBAAECggEADEAKVU6BgOlZh51PBrwDhHHyXiE+tH15xAOvcDFl+HtE\nc8/VTyt+debb0g5fSarpDI8iW608GhkAxJrpD56H5NDaMsFcIcz3fAv4qgzgbyTw\ny6gPOF/J4zjBlqGggJZ/WfKDEfzwF1F7/iTNtoj/P5qHTdY7i10DwLVS9Kwmk5sc\nms2dYB366apE21Qx6zSNQQFZY29fU3XWfGV4CNINdeifVWRvMKfijK2dfQkBIA7H\nPlryfpOQnzrI00Wx2P0CfyrOkG4o68KKtZENXwGt47JV4deJl2chQSwvkH97OwO2\nyFPeu6itbnJbxSYaBTA1EMrOinGAZ5TBWyOx0/o2WQKBgQD8H0i3gR80/Oyvvr/o\nZtSg0eoEi1U3U0wMvx8qMXiQFrXmxmnoXM9iMptMFjbDCEKcYJu+yeTIzi25ffyh\n/iQaxYMDUTyivGzv+YIE0HvNH/n+BtUTHm38PU2EexbpPZuIcFIKZ2hHpRH6Lrra\nvuzqKGPLYjbB//BoYdrrH4EsxQKBgQDSFOWHyNqqlGziwIXsMFPms7vvXbG9wGIf\nqu3ZkODUTRzbm4jTRCjrC+sZQkcs3FTbyFQn62QFtHvz166NEf3mNa7iGMxvqtTC\nDnaq+Xso/LdPXDOhUEa27P1n+HaktBMSFK8QPn9URL2s1HTvgZmp4iKRRtmmkiNE\ntw+CvhjE8wKBgQDvQASyVq61itpUQBA+yu41ml2XaF06fiop4mgBkyaUnWiKkXjJ\nDuGhjuJ+Bop682i6mpbRKyeXQshzQNIvK0s5uHqF+F4xE9vQshYm2WzSD+kcnYEv\nfm3iso3QDTqFpXfltqizxMNZUZTIs/WPRSTvY9qnkxDhci3B8DJdcu0S/QKBgErd\njYqdJmfhqwgHqfIoqs2tQY0k66F+fLliVY7SFX0y2dTdEZ6QTLCut6JxvyGah1cn\nhe4P8b4iuoWEWD0Hq16txNvoEHq++0EInHuDmsNZhA3xAqk7DWhE/m1d2xII5j7s\nRhLY4tFqCdocgGuV2Of0oXL6N7gnng/v2MQz8GnHAoGBALZfHwD77HqiZMO8YNId\npDGtwVSdL1j4CSHZaygoVMyArI0DjOiKSihnq/6a/fxPcE20ETupGmev6/s3pN6Z\nTLvxposnlNTeaIt2df/dkDRy+Laj0BXBHd5BIroNIuyIjvs2+KaQAFd6bSXGXT2+\nu/uBczOk4FUspR/XF1gyHQyV\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-fbsvc@siswar-bazar.iam.gserviceaccount.com",
      "client_id": "107158617119345223601",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40siswar-bazar.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials = await auth
        .obtainAccessCredentialsViaServiceAccount(
          auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
          scopes,
          client,
        );

    client.close();

    return credentials.accessToken.data;
  }

  Future<String?> getFcmToken(String customerId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data['fcm_token'];
      } else {
        print("Document does not exist");
        return null;
      }
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }

  Future<void> sendFCMMessage(String customerId, String subt) async {
    final String serverKey = await getAccessToken(); // Your FCM server key
    final String token = await getFcmToken(customerId) ?? "";
    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/siswar-bazar/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': token,
        'notification': {
          'body': 'Check your Order tracking',
          'title': '$subt 🥳',
        },
      },
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('FCM message sent successfully');
    } else {
      print('Failed to send FCM message: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchTotalOrdersAndPrice() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    double totalOrderPrice = 0.0;
    int totalOrders = 0;
    final pref = await SharedPreferences.getInstance();
    String token = pref.getString('deliveryBoyId') ?? "";

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('orders')
          .where('deliveryBoyId', isEqualTo: token)
          .get();

      totalOrders = querySnapshot.docs.length;

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        double price;
        int itemCount;

        // Safely parse price
        var rawPrice = data['price'];
        if (rawPrice is int) {
          price = rawPrice.toDouble();
        } else if (rawPrice is double) {
          price = rawPrice;
        } else if (rawPrice is String) {
          price = double.tryParse(rawPrice.trim()) ?? 0.0;
        } else {
          price = 0.0;
        }

        // Safely parse itemCount
        var rawItemCount = data['itemCount'];
        if (rawItemCount is int) {
          itemCount = rawItemCount;
        } else if (rawItemCount is String) {
          itemCount = int.tryParse(rawItemCount.trim()) ?? 0;
        } else {
          itemCount = 0;
        }

        totalOrderPrice += (price * itemCount);
      }

      return {'totalOrders': totalOrders, 'totalOrderPrice': totalOrderPrice};
    } catch (e) {
      print('Error fetching orders: $e');
      return {'totalOrders': 0, 'totalOrderPrice': 0.0};
    }
  }

  void onStatusChanged(String status) async {
    orderStatus = status;
    notifyListeners();
  }

  Future<void> getDeliveryBoy() async {
    profileLoadFailed = false;
    final pref = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid ??
        pref.getString('deliveryBoyId') ??
        '';
    if (uid.isEmpty) {
      deliveryBoy = null;
      profileLoadFailed = true;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(uid)
          .get();
      if (!snapshot.exists || snapshot.data() == null) {
        deliveryBoy = null;
        profileLoadFailed = true;
        notifyListeners();
        return;
      }
      deliveryBoy = DeliveryBoyModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        snapshot.id,
      );
      profileLoadFailed = false;
      notifyListeners();
    } catch (e) {
      deliveryBoy = null;
      profileLoadFailed = true;
      print(e.toString());
      notifyListeners();
    }
  }

  Future<void> getTotalOrders() async {
    final pref = await SharedPreferences.getInstance();
    String id = pref.getString('deliveryBoyId') ?? "";
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: id)
        .get();
    totalOrders = snapshot.docs.map((doc) {
      return OrderModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> getOrders() async {
    orders = null;
    newOrders.clear();
    myTransistOrders.clear();
    myAcceptedOrders.clear();
    myPickedOrders.clear();
    myCancelledOrders.clear();
    myCompletedOrders.clear();
    final pref = await SharedPreferences.getInstance();
    String id = pref.getString('deliveryBoyId') ?? "";
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      orders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      notifyListeners();
      log(orders!.length.toString());
      if (orders != null) {
        for (var item in orders!) {
          if (item.deliveryBoyId == '' &&
              item.isDelivered == false &&
              item.orderStatus == 'Order Confirm') {
            newOrders.add(item);
            notifyListeners();
          }
          log(newOrders.length.toString());
          if (item.deliveryBoyId == id && item.isCancelled) {
            myCancelledOrders.add(item);
          } else if (item.deliveryBoyId == id && item.isDelivered) {
            myCompletedOrders.add(item);
          } else if (item.deliveryBoyId == id) {
            final st = item.orderStatus.toLowerCase();
            if (st.contains('picked') || st.contains('on the way')) {
              myPickedOrders.add(item);
              myTransistOrders.add(item);
            } else {
              myAcceptedOrders.add(item);
              myTransistOrders.add(item);
            }
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> updateStatus(String status, String id) async {
    print(selectedOrder!.orderStatus);
    if (status == 'Going to Shop') {
      await FirebaseFirestore.instance.collection('orders').doc(id).set({
        "order_status": status,
        "driverShop": DateTime.now().toString(),
      }, SetOptions(merge: true));
    } else if (status == "Order Picked") {
      await FirebaseFirestore.instance.collection('orders').doc(id).set({
        "order_status": status,
        "pickedTime": DateTime.now().toString(),
      }, SetOptions(merge: true));
    } else if (status == 'On the Way') {
      await FirebaseFirestore.instance.collection('orders').doc(id).set({
        "order_status": status,
        "onTheWayTime": DateTime.now().toString(),
      }, SetOptions(merge: true));
    }
    selectedOrder!.orderStatus == status;
    orderStatus = status;
    notifyListeners();
    print(selectedOrder!.orderStatus);
  }

  void showConfirmationDialog(
    BuildContext context,
    String id,
    String customerId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Order"),
          content: const Text("Do you want to take this order?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final pref = await SharedPreferences.getInstance();
                String ID = pref.getString('deliveryBoyId') ?? "";
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(id)
                    .update({"deliveryBoyId": ID});
                getOrders();
                sendFCMMessage(customerId, 'Delivery Boy Accepted your Order');
                // Handle the order confirmation logic here
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Order confirmed by you!")),
                );
              },
              child: const Text(
                "Confirm",
                style: TextStyle(color: GlobalVariables.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> completeOrder(BuildContext context, String id) async {
    OrderModel? order = selectedOrder;
    if (orders != null) {
      for (final o in orders!) {
        if (o.id == id) {
          order = o;
          break;
        }
      }
    }
    if (order == null) return;
    final earning = order.deliveryCharge > 0
        ? order.deliveryCharge.toDouble()
        : order.products.fold<double>(
            0,
            (s, p) => s + ((p.price ?? 0) * (p.itemCount ?? 0)) * 0.05,
          );

    await FirebaseFirestore.instance.collection('orders').doc(id).set({
      "isDelivered": true,
      "isPaid": true,
      "order_status": "Order Delivered",
      "deliveredTime": DateTime.now().toString(),
    }, SetOptions(merge: true));

    final pref = await SharedPreferences.getInstance();
    final riderId = pref.getString('deliveryBoyId') ?? '';
    if (riderId.isNotEmpty && earning > 0) {
      await FirebaseFirestore.instance.collection('delivery_boys').doc(riderId).set({
        'wallet_balance': FieldValue.increment(earning),
        'total_earnings': FieldValue.increment(earning),
        'completed_orders': FieldValue.increment(1),
        'total_deliveries': FieldValue.increment(1),
      }, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(riderId)
          .collection('wallet_transactions')
          .add({
        'type': 'delivery_earning',
        'amount': earning,
        'order_id': id,
        'note': 'Delivery completed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    getOrders();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order delivered! Earnings credited to wallet.')),
      );
      Navigator.pop(context);
    }
  }

  void getCashByCustomer(BuildContext context, String amount, String id) {
    priceController.text = amount;
    notifyListeners();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: size.width,
            constraints: BoxConstraints(
              maxHeight: size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Payment Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Display Amount
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Amount to Collect",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹$amount",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // QR Code
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Scan QR Code to Pay",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Image.asset(
                                'assets/images/qr.png',
                                height: 200,
                                width: 200,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Read-only amount field
                        TextField(
                          controller: priceController,
                          readOnly: true,
                          enabled: false,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Amount (₹)",
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          completeOrder(context, id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.green,
                              content: Text("Order Delivered"),
                            ),
                          );
                        },
                        child: const Text("Complete Order"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showOrderConfirmationDialog(
    BuildContext context,
    String id,
    String userID,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Order"),
          content: const Text("Do you want to complete this order?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel action
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () {
                sendFCMMessage(userID, 'Your Order Delivered Successfully');
                // Add your order completion logic here
                completeOrder(context, id);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }
}
