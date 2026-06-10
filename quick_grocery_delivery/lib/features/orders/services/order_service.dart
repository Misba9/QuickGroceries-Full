import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:quick_grocery_delivery/features/orders/screens/delivery_details_screen.dart';
import 'package:quick_grocery_delivery/features/orders/widgets/confirm_delivery_dialog.dart';
import 'package:quick_grocery_delivery/services/delivery_ops_api.dart';
import 'package:quick_grocery_delivery/services/delivery_trip_tracker.dart';
import 'package:quick_grocery_delivery/utils/delivery_route_utils.dart';
import 'package:quick_grocery_delivery/core/delivery_push_initializer.dart';
import 'package:quick_grocery_delivery/core/firestore_query_errors.dart';
import 'package:quick_grocery_delivery/core/order_lifecycle.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/models/delivery_boy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService extends ChangeNotifier {
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  String _subscribedRiderId = '';
  bool _ordersUseServerSort = true;
  int _lastNewOrderCount = 0;
  bool _ordersPrimed = false;

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
  String? pickupActionOrderId;
  String? deliveryActionOrderId;
  String? customerNotReachableOrderId;
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
    final pref = await SharedPreferences.getInstance();
    final riderId = pref.getString('deliveryBoyId') ?? '';
    if (riderId.isEmpty) {
      return {'totalOrders': 0, 'totalOrderPrice': 0.0};
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryBoyId', isEqualTo: riderId)
          .where('isDelivered', isEqualTo: true)
          .get();

      double totalOrderPrice = 0;
      for (final doc in querySnapshot.docs) {
        final order = OrderModel.fromFirestore(
          doc.data(),
          doc.id,
        );
        totalOrderPrice += _orderEarning(order);
      }

      return {
        'totalOrders': querySnapshot.docs.length,
        'totalOrderPrice': totalOrderPrice,
      };
    } catch (e) {
      print('Error fetching orders: $e');
      return {'totalOrders': 0, 'totalOrderPrice': 0.0};
    }
  }

  double _orderEarning(OrderModel order) {
    if (order.deliveryCharge > 0) return order.deliveryCharge.toDouble();
    final bill = order.bill;
    if (bill != null && bill['deliveryFee'] != null) {
      return (bill['deliveryFee'] as num).toDouble();
    }
    return order.products.fold<double>(
      0,
      (s, p) => s + ((p.price ?? 0) * (p.itemCount ?? 0)) * 0.05,
    );
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
    _sortNewestFirst(totalOrders);
    notifyListeners();
  }

  Future<void> getOrders() async {
    startRealtimeOrders();
  }

  int get pendingAssignmentCount => newOrders.length;

  /// Order id currently eligible for live GPS mirroring on `orders/{id}/live/rider`.
  String? get activeTrackingOrderId {
    for (final o in [
      ...myTransistOrders,
      ...myPickedOrders,
      ...myAcceptedOrders,
      ...newOrders,
    ]) {
      if (OrderLifecycle.isActiveDelivery(_statusId(o))) return o.id;
    }
    return null;
  }

  Future<String> _currentRiderId() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('deliveryBoyId') ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
  }

  Future<void> startRealtimeOrders() async {
    final riderId = await _currentRiderId();
    if (riderId.isEmpty) return;

    if (_subscribedRiderId == riderId && _ordersSub != null) return;

    await _ordersSub?.cancel();
    _subscribedRiderId = riderId;
    _ordersUseServerSort = true;
    orders = null;
    _ordersPrimed = false;
    _lastNewOrderCount = 0;
    notifyListeners();

    _listenRiderOrders(riderId);
  }

  Query<Map<String, dynamic>> _riderOrdersQuery(String riderId) {
    final base = FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryBoyId', isEqualTo: riderId);
    if (_ordersUseServerSort) {
      return base.orderBy('createdAt', descending: true);
    }
    return base;
  }

  void _listenRiderOrders(String riderId) {
    _ordersSub?.cancel();
    _ordersSub = _riderOrdersQuery(riderId).snapshots().listen(
      (snap) {
        orders = snap.docs
            .map(
              (d) => OrderModel.fromFirestore(
                d.data(),
                d.id,
              ),
            )
            .toList();
        _rebucketOrders(riderId);
        notifyListeners();
      },
      onError: (Object e, StackTrace stack) {
        if (_ordersUseServerSort && FirestoreQueryErrors.isMissingIndex(e)) {
          if (kDebugMode) {
            debugPrint(
              'orders stream: createdAt index missing — falling back to client sort',
            );
          }
          _ordersUseServerSort = false;
          _listenRiderOrders(riderId);
          return;
        }
        if (kDebugMode) {
          FirestoreQueryErrors.log('orders stream error', e, stack);
        }
      },
    );
  }

  static void _sortNewestFirst(List<OrderModel> list) {
    list.sort(OrderModel.compareNewestFirst);
  }

  String _statusId(OrderModel item) {
    return OrderLifecycle.resolveStatus({
      'status': item.modernStatus,
      'order_status': item.orderStatus,
      'isCancelled': item.isCancelled,
      'isDelivered': item.isDelivered,
    });
  }

  void _rebucketOrders(String riderId) {
    newOrders.clear();
    myTransistOrders.clear();
    myAcceptedOrders.clear();
    myPickedOrders.clear();
    myCancelledOrders.clear();
    myCompletedOrders.clear();

    final list = orders ?? [];
    for (final item in list) {
      if (item.isCancelled) {
        if (item.deliveryBoyId == riderId) myCancelledOrders.add(item);
        continue;
      }
      if (item.isDelivered) {
        if (item.deliveryBoyId == riderId) myCompletedOrders.add(item);
        continue;
      }

      if (_isNewOffer(item, riderId)) {
        newOrders.add(item);
        continue;
      }

      if (item.deliveryBoyId == riderId) {
        final st = _statusId(item);
        if (st == OrderLifecycle.pickedUp || st == OrderLifecycle.outForDelivery) {
          myPickedOrders.add(item);
          myTransistOrders.add(item);
        } else if (OrderLifecycle.isPickupPhase(st)) {
          myAcceptedOrders.add(item);
        }
      }
    }

    _sortNewestFirst(newOrders);
    _sortNewestFirst(myAcceptedOrders);
    _sortNewestFirst(myPickedOrders);
    _sortNewestFirst(myTransistOrders);
    _sortNewestFirst(myCancelledOrders);
    _sortNewestFirst(myCompletedOrders);

    if (_ordersPrimed) {
      if (newOrders.length > _lastNewOrderCount) {
        _playNewOrderAlert();
      }
    } else {
      _ordersPrimed = true;
    }
    _lastNewOrderCount = newOrders.length;
  }

  bool _isNewOffer(OrderModel item, String riderId) {
    if (item.isDelivered || item.isCancelled) return false;
    if (item.deliveryBoyId != riderId || riderId.isEmpty) return false;
    return OrderLifecycle.needsRiderAcceptance(_statusId(item));
  }

  Future<void> _playNewOrderAlert() async {
    if (DeliveryPushInitializer.recentlyHandledByFcm) {
      if (kDebugMode) {
        debugPrint('[DeliveryNotify] skip Firestore alert — FCM already handled');
      }
      return;
    }
    await DeliveryPushInitializer.playAssignmentAlert();
  }

  Future<OrderModel?> acceptDelivery(String orderId, {OrderModel? order}) async {
    OrderModel? source = order;
    if (source == null) {
      for (final o in [...newOrders, ...?orders]) {
        if (o.id == orderId) {
          source = o;
          break;
        }
      }
    }
    if (source == null) return null;

    final patch = await _buildRiderAcceptancePatch(source);
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update(patch);

    return source.copyWith(
      modernStatus: OrderLifecycle.deliveryAssigned,
      orderStatus: OrderLifecycle.legacyLabel(OrderLifecycle.deliveryAssigned),
      vendorName: (patch['vendorName'] ?? source.vendorName).toString(),
      storeName: (patch['storeName'] ?? source.storeName).toString(),
      vendorPhone: (patch['vendorPhone'] ?? source.vendorPhone).toString(),
      pickupAddress: (patch['pickupAddress'] ?? source.pickupAddress).toString(),
      pickupLat: (patch['pickupLat'] as num?)?.toDouble() ?? source.pickupLat,
      pickupLng: (patch['pickupLng'] as num?)?.toDouble() ?? source.pickupLng,
      routeDistanceKm:
          (patch['routeDistanceKm'] as num?)?.toDouble() ?? source.routeDistanceKm,
      expectedDeliveryMinutes: (patch['expectedDeliveryMinutes'] as num?)?.toInt() ??
          source.expectedDeliveryMinutes,
    );
  }

  OrderModel? orderById(String id) {
    for (final o in [
      ...newOrders,
      ...myAcceptedOrders,
      ...myPickedOrders,
      ...myTransistOrders,
      ...?orders,
    ]) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<void> markReachedStore(String orderId) async {
    pickupActionOrderId = orderId;
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.reachedStore),
        'status': OrderLifecycle.reachedStore,
        'reachedStoreAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      pickupActionOrderId = null;
      notifyListeners();
    }
  }

  Future<void> markPickedUp(String orderId) async {
    pickupActionOrderId = orderId;
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.pickedUp),
        'status': OrderLifecycle.pickedUp,
        'pickedTime': DateTime.now().toIso8601String(),
        'pickedUpAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      pickupActionOrderId = null;
      notifyListeners();
    }
  }

  @Deprecated('Use markReachedStore')
  Future<void> startHeadingToStore(String orderId) async {
    await markReachedStore(orderId);
  }

  Future<void> rejectOrder(String orderId) async {
    final riderId = await _currentRiderId();
    if (riderId.isEmpty) return;
    await DeliveryOpsApi().cancelOrderByRider(
      orderId: orderId,
      riderId: riderId,
    );
  }

  void showAcceptRejectDialog(
    BuildContext context,
    OrderModel order,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Delivery Assigned'),
        content: Text(
          'Accept delivery for ${order.customerName}?\n${order.address}',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await rejectOrder(order.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery rejected')),
                );
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final accepted = await acceptDelivery(order.id, order: order);
              if (context.mounted && accepted != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryDetailsScreen(order: accepted),
                  ),
                );
              }
            },
            child: const Text('Accept Delivery'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }

  Future<void> updateStatus(String status, String id) async {
    String statusId;
    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'Reached Store') {
      statusId = OrderLifecycle.reachedStore;
      patch['reachedStoreAt'] = FieldValue.serverTimestamp();
    } else if (status == 'Order Picked') {
      statusId = OrderLifecycle.pickedUp;
      patch['pickedTime'] = DateTime.now().toIso8601String();
    } else if (status == 'On the Way') {
      statusId = OrderLifecycle.outForDelivery;
      patch['onTheWayTime'] = DateTime.now().toIso8601String();
    } else {
      statusId = _statusId(selectedOrder!);
    }

    patch['order_status'] = OrderLifecycle.legacyLabel(statusId);
    patch['status'] = statusId;

    await FirebaseFirestore.instance.collection('orders').doc(id).set(
      patch,
      SetOptions(merge: true),
    );
    orderStatus = OrderLifecycle.legacyLabel(statusId);
    notifyListeners();
  }

  void showConfirmationDialog(
    BuildContext context,
    String id,
    String customerId,
  ) {
    OrderModel? order;
    for (final o in [...newOrders, ...?orders]) {
      if (o.id == id) {
        order = o;
        break;
      }
    }
    if (order != null) {
      showAcceptRejectDialog(context, order);
      return;
    }
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
                await acceptDelivery(id);
                sendFCMMessage(customerId, 'Delivery Boy Accepted your Order');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery accepted')),
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

  Future<void> markOutForDelivery(String orderId) async {
    deliveryActionOrderId = orderId;
    notifyListeners();
    try {
      DeliveryTripTracker.instance.start(orderId);
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.outForDelivery),
        'status': OrderLifecycle.outForDelivery,
        'onTheWayTime': DateTime.now().toIso8601String(),
        'outForDeliveryAt': FieldValue.serverTimestamp(),
        'deliveryLegStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } finally {
      deliveryActionOrderId = null;
      notifyListeners();
    }
  }

  Future<void> reportCustomerNotReachable(
    BuildContext context,
    String orderId,
  ) async {
    customerNotReachableOrderId = orderId;
    notifyListeners();
    try {
      final riderId = await _currentRiderId();
      if (riderId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rider session not found')),
          );
        }
        return;
      }
      await DeliveryOpsApi().reportCustomerNotReachable(
        orderId: orderId,
        riderId: riderId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin notified — customer marked not reachable'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      customerNotReachableOrderId = null;
      notifyListeners();
    }
  }

  Future<void> recordCodPayment({
    required String orderId,
    required String collectionMethod,
  }) async {
    final riderId = await _currentRiderId();
    if (riderId.isEmpty) {
      throw Exception('Rider session not found');
    }
    await DeliveryOpsApi().recordDeliveryPayment(
      orderId: orderId,
      riderId: riderId,
      collectionMethod: collectionMethod,
    );
    notifyListeners();
  }

  Future<void> markDelivered(BuildContext context, String id) async {
    deliveryActionOrderId = id;
    notifyListeners();
    try {
      final order = orderById(id);
      if (order != null && order.payment.requiresCodCollection) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collect payment first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final metrics = DeliveryTripTracker.instance.metrics();
      final riderId = await _currentRiderId();
      if (riderId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rider session not found')),
          );
        }
        return;
      }

      await DeliveryOpsApi().confirmDelivery(
        orderId: id,
        riderId: riderId,
        deliveryDurationSec: metrics.durationSec,
        distanceTravelledKm: metrics.distanceKm,
      );

      DeliveryTripTracker.instance.stop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order delivered! Earnings credited to wallet.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      deliveryActionOrderId = null;
      notifyListeners();
    }
  }

  Future<void> completeOrder(BuildContext context, String id) async {
    final confirmed = await showConfirmDeliveryDialog(context);
    if (!confirmed || !context.mounted) return;
    await markDelivered(context, id);
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
                        onPressed: () async {
                          Navigator.pop(context);
                          await completeOrder(context, id);
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

  Future<void> showOrderConfirmationDialog(
    BuildContext context,
    String id,
    String userID,
  ) async {
    final confirmed = await showConfirmDeliveryDialog(context);
    if (!confirmed || !context.mounted) return;
    await markDelivered(context, id);
    if (context.mounted && userID.isNotEmpty) {
      sendFCMMessage(userID, 'Your order has been delivered successfully.');
    }
  }

  Future<Map<String, dynamic>> _buildRiderAcceptancePatch(OrderModel order) async {
    final patch = <String, dynamic>{
      'order_status': OrderLifecycle.legacyLabel(OrderLifecycle.deliveryAssigned),
      'status': OrderLifecycle.deliveryAssigned,
      'riderAcceptedAt': FieldValue.serverTimestamp(),
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    var vendorName = order.vendorName;
    var storeName = order.storeName;
    var vendorPhone = order.vendorPhone;
    var pickupAddress = order.pickupAddress;
    var pickupLat = order.pickupLat;
    var pickupLng = order.pickupLng;
    final vendorId = order.primaryVendorId;

    if (vendorId.isNotEmpty &&
        (vendorName.isEmpty || pickupAddress.isEmpty)) {
      final snap = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(vendorId)
          .get();
      if (snap.exists) {
        final d = snap.data() ?? {};
        storeName = (d['shopName'] ?? d['shop_name'] ?? storeName).toString();
        vendorName = (d['ownerName'] ?? d['name'] ?? vendorName).toString();
        if (vendorName.isEmpty) vendorName = storeName;
        vendorPhone = (d['phone'] ?? vendorPhone).toString();
        pickupAddress =
            (d['shopAddress'] ?? d['shop_address'] ?? pickupAddress).toString();
        pickupLat ??=
            _optionalDouble(d['lat'] ?? d['latitude'] ?? d['shop_lat']);
        pickupLng ??=
            _optionalDouble(d['lng'] ?? d['longitude'] ?? d['shop_lng']);
      }
    }

    double? routeKm = order.routeDistanceKm;
    if ((routeKm == null || routeKm <= 0) &&
        pickupLat != null &&
        pickupLng != null &&
        order.latitude != null &&
        order.longitude != null) {
      routeKm = DeliveryRouteUtils.haversineKm(
        pickupLat,
        pickupLng,
        order.latitude!,
        order.longitude!,
      );
    }

    int? etaMin = order.expectedDeliveryMinutes;
    if ((etaMin == null || etaMin <= 0) && routeKm != null && routeKm > 0) {
      etaMin = DeliveryRouteUtils.estimateMinutes(routeKm);
    }

    patch['vendorId'] = vendorId;
    patch['vendorName'] = vendorName;
    if (storeName.isNotEmpty) {
      patch['storeName'] = storeName;
      patch['store_name'] = storeName;
    }
    patch['vendorPhone'] = vendorPhone;
    patch['pickupAddress'] = pickupAddress;
    if (pickupLat != null) patch['pickupLat'] = pickupLat;
    if (pickupLng != null) patch['pickupLng'] = pickupLng;
    if (routeKm != null && routeKm > 0) patch['routeDistanceKm'] = routeKm;
    if (etaMin != null && etaMin > 0) {
      patch['expectedDeliveryMinutes'] = etaMin;
    }

    return patch;
  }

  double? _optionalDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
