import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/models/coupon_model.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:provider/provider.dart';

class CartService extends ChangeNotifier {
  List<OrderModel> cartList = [];
  List<CouponModel>? coupon;

  int? selectedCoupon;
  int deliveryCharge = 0;
  int standardDeliveryCharge = 0;
  int minumOrder = 100;
  int platformFee = 0;
  int handlingCharge = 0;
  String selectedDeliveryType = 'standard';
  bool isLoading = false;
  bool _placementLock = false;

  void resetSessionForLogout() {
    cartList = [];
    coupon = null;
    selectedCoupon = null;
    deliveryCharge = 0;
    standardDeliveryCharge = 0;
    minumOrder = 100;
    platformFee = 0;
    handlingCharge = 0;
    selectedDeliveryType = 'standard';
    isLoading = false;
    _placementLock = false;
    _zoneDeliveryCharge = null;
    notifyListeners();
  }

  // Zone-based delivery charge (will be set based on user's pin code)
  double? _zoneDeliveryCharge;
  double? get zoneDeliveryCharge => _zoneDeliveryCharge;
  void onItemAdd(int orderIndex, int productIndex) {
    cartList[orderIndex].products[productIndex].itemCount++;
    notifyListeners();
  }

  void onDeliveryTypeChanged(String vaue) {
    selectedDeliveryType = vaue;
    notifyListeners();
  }

  void onCouponSelected(int coupon) {
    selectedCoupon = coupon;
    notifyListeners();
  }

  void onItemRemove(int orderIndex, int productIndex) {
    final product = cartList[orderIndex].products[productIndex];

    if (product.itemCount > 1) {
      product.itemCount--;
    } else {
      cartList[orderIndex].products.removeAt(productIndex);

      // Optionally remove entire order if no products left
      if (cartList[orderIndex].products.isEmpty) {
        cartList.removeAt(orderIndex);
      }
    }

    notifyListeners();
  }

  Future<void> fetchCoupons() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .get();

      coupon = snapshot.docs.map((doc) {
        return CouponModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      notifyListeners();
    } catch (_) {}
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

  Future<void> getDeliveryCharge() async {
    isLoading = true;

    try {
      // Fetch standard delivery charge
      DocumentSnapshot snapshot2 = await FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc('b1slJi5ePvTQ5JHeYtWx')
          .get();
      // Fetch minimum order amount
      DocumentSnapshot snapshot3 = await FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc('dpKk0Q4CNNwgUlltn6OM')
          .get();
      // Fetch platform fee document which contains all three fees
      DocumentSnapshot platformFeeDoc = await FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc('r6ArqhMeZYDJnpFo6EJP')
          .get();

      var doc2 = snapshot2.data() as Map<String, dynamic>;
      var doc3 = snapshot3.data() as Map<String, dynamic>;
      var platformFeeDocData = platformFeeDoc.data() as Map<String, dynamic>;

      // Extract values from platform fee document
      standardDeliveryCharge = doc2['amount'];
      minumOrder = doc3['amount'];

      // Get all three fees from the platform fee document
      platformFee = platformFeeDocData['amount'] ?? 0;
      handlingCharge = platformFeeDocData['handling_charge'] ?? 0;
      deliveryCharge = platformFeeDocData['delivery_charge'] ?? 0;

      // Also fetch zone-based delivery charge
      await _updateZoneDeliveryCharge();

      isLoading = false;

      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  /// Get delivery charge from delivery zone based on user's pin code
  Future<void> _updateZoneDeliveryCharge() async {
    try {
      // Get address service to access pin code
      // Note: This requires context, so we'll pass it from the screen
      _zoneDeliveryCharge = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating zone delivery charge: $e');
    }
  }

  /// Get delivery charge from delivery zone based on pin code
  /// Returns zone delivery charge if available, otherwise falls back to default
  Future<double> getDeliveryChargeFromZone(String? pinCode) async {
    if (pinCode == null || pinCode.isEmpty) {
      // Fallback to default delivery charge
      return selectedDeliveryType == 'standard'
          ? standardDeliveryCharge.toDouble()
          : deliveryCharge.toDouble();
    }

    try {
      // Get delivery zone service
      final deliveryZoneService = DeliveryZoneService();
      final zone = await deliveryZoneService.getZoneByPinCode(pinCode);

      if (zone != null) {
        _zoneDeliveryCharge = zone.deliveryCharge;
        notifyListeners();
        return zone.deliveryCharge;
      } else {
        // No zone found, use default
        return selectedDeliveryType == 'standard'
            ? standardDeliveryCharge.toDouble()
            : deliveryCharge.toDouble();
      }
    } catch (e) {
      debugPrint('Error getting delivery charge from zone: $e');
      // Fallback to default
      return selectedDeliveryType == 'standard'
          ? standardDeliveryCharge.toDouble()
          : deliveryCharge.toDouble();
    }
  }

  /// Get current delivery charge (zone-based if available, otherwise default)
  Future<double> getCurrentDeliveryCharge(String? pinCode) async {
    if (_zoneDeliveryCharge != null) {
      return _zoneDeliveryCharge!;
    }

    // Try to get from zone
    return await getDeliveryChargeFromZone(pinCode);
  }

  Future<void> sendFCMMessage(String token) async {
    final String serverKey = await getAccessToken(); // Your FCM server key

    final String fcmEndpoint =
        'https://fcm.googleapis.com/v1/projects/siswar-bazar/messages:send';
    // final currentFCMToken = await FirebaseMessaging.instance.getToken();

    final Map<String, dynamic> message = {
      'message': {
        'token': token,
        'notification': {
          'body': 'Check your new Order!',
          'title': 'New Order Recived 🥳',
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

  Future<void> addCartItem(BuildContext context, OrderModel newOrder) async {
    final newProduct = newOrder.products.first;
    final existingOrderIndex = cartList.indexWhere(
      (cartOrder) => cartOrder.products.any((p) => p.name == newProduct.name),
    );

    if (existingOrderIndex != -1) {
      final existingOrder = cartList[existingOrderIndex];

      final productIndex = existingOrder.products.indexWhere(
        (p) => p.name == newProduct.name,
      );

      if (productIndex != -1) {
        existingOrder.products[productIndex].itemCount += newProduct.itemCount;
      } else {
        existingOrder.products.add(newProduct);
      }
    } else {
      cartList.add(newOrder);
    }

    notifyListeners();

    Navigator.push(context, AppPageRoutes.cart());
  }

  Future<String?> getAdminFcmToken() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc('ctgKyYf9rvRJZNKTdLs0')
          .get();

      if (doc.exists) {
        return doc.get('fcm_token');
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print('Error fetching fcm_token: $e');
      return null;
    }
  }

  Future<void> addCartItemto(
    BuildContext context,
    List<ProductModel> selectedProduct,
    AddressModel address,
    String currentAddress,
    LatLng currentLatLng,
  ) async {
    if (_placementLock || isLoading) return;
    _placementLock = true;
    isLoading = true;
    notifyListeners();

    try {
      List<ProductItem> productItems = selectedProduct.map((v) {
      return ProductItem(
        name: v.name,
        image: v.image,
        description: v.description,
        category: v.category,
        unit: v.unit,
        price: v.unitSellingPrice,
        slashedPrice:
            v.hasDiscount ? v.unitOriginalPrice : v.unitSellingPrice,
        itemCount: v.itemCount,
        vendorId: v.vendorId,
      );
    }).toList();

    // Get delivery charge from zone based on address pin code
    // Extract pin code from address string or use AddressService
    final addressService = Provider.of<AddressService>(context, listen: false);
    final pinCode = addressService.pinCode;
    final zoneDeliveryCharge = await getDeliveryChargeFromZone(pinCode);

    double itemTotal = selectedProduct.fold(
      0.0,
      (sum, product) => sum + (product.unitSellingPrice * product.itemCount),
    );

    // Apply free delivery logic (if order >= 99)
    final finalDeliveryCharge = itemTotal >= 99
        ? 0
        : zoneDeliveryCharge.toInt();

    OrderModel order = OrderModel(
      lat: currentLatLng.latitude,
      lng: currentLatLng.longitude,
      currentLocation: currentAddress,
      uuid: FirebaseAuth.instance.currentUser!.uid,
      id: DateTime.now().millisecondsSinceEpoch.toString(), // or generate UUID
      products: productItems,
      createdDate: DateTime.now().toString(),
      address: "${address.address} ${address.area}",
      customerName: address.name,
      phone: address.mobile,
      isPaid: false,
      orderStatus: 'Waiting',
      deliveryBoyId: '',
      isDelivered: false,
      isCancelled: false,
      confimedTime: '',
      driverGoShopTime: '',
      onTheWayTime: '',
      orderDeliveredTime: '',
      orderPickedTime: '',
      deliveryType: selectedDeliveryType,
      deliveryCharge: finalDeliveryCharge,
      isRated: false,
      rating: 0,
    );

    // Send FCM & store to Firestore
    String fcm = await getAdminFcmToken() ?? "";
    sendFCMMessage(fcm); // uncomment if needed

    DocumentReference s = await FirebaseFirestore.instance
        .collection('orders')
        .add(order.toMap());

    log("Order ID: ${s.id}");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(
          orderId: s.id,
          fromCheckout: true,
        ),
      ),
      (Route<dynamic> route) => false,
    );

      selectedProduct.clear();
    } finally {
      _placementLock = false;
      isLoading = false;
      notifyListeners();
    }
  }

  double getTotalAmount() {
    double totalAmount = 0.0;

    for (OrderModel order in cartList) {
      for (ProductItem product in order.products) {
        totalAmount += product.price * product.itemCount;
      }
    }

    return totalAmount;
  }
}
