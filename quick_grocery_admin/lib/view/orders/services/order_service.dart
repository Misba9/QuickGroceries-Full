import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderService extends ChangeNotifier {
  CustomerModel? customer;
  VendorModel? vendor;
  AddressModel? address;
  List<OrderModel>? orders;
  List<OrderModel>? newOrders;
  List<OrderModel>? cancelledOrders;
  List<OrderModel>? deliveredOrders;

  Future<void> getCustomer(String id) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(id)
          .get();
      customer = CustomerModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> cancellOrder(BuildContext context, String id) async {
    try {
      await FirebaseFirestore.instance.collection('cart').doc(id).update({
        "isCancelled": true,
      });

      getOrders();
      Navigator.pop(context);
      notifyListeners();
    } catch (e) {}
  }

  Future<void> getVendor(String id) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .doc(id)
          .get();
      vendor = VendorModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {}
  }

  Future<void> getAddress(String id) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('address')
          .doc(id)
          .get();

      address = AddressModel.fromFirestore(
        snapshot.data() as Map<String, dynamic>,
        id,
      );
      notifyListeners();
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }

  Future<void> getOrders() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();

      List<OrderModel> allOrders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      DateTime today = DateTime.now();
      String todayDateString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      newOrders = allOrders.where((order) {
        DateTime orderDate = DateTime.parse(order.createdDate);
        String orderDateString =
            "${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}";

        return orderDateString == todayDateString && !order.isCancelled;
      }).toList();

      cancelledOrders = allOrders.where((order) => order.isCancelled).toList();

      deliveredOrders = allOrders.where((order) => order.isDelivered).toList();

      orders = allOrders.where((order) => !order.isCancelled).toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }
}
