import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserService extends ChangeNotifier {
  List<CustomerModel>? customers;
  List<AddressModel>? addresses;
  List<OrderModel>? orders;
  List<CustomerModel> filteredCustomers = [];

  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();

      customers = snapshot.docs.map((doc) {
        return CustomerModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      filteredCustomers = customers!;
      notifyListeners();
    } catch (_) {}
  }

  void toggleChange(int i) {
    customers![i].isBlocked = !customers![i].isBlocked;
    notifyListeners();
  }

  Future<void> getAddress(String id) async {
    try {
      // Get the products collection from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('address')
          .where('user_id', isEqualTo: id)
          .get();

      addresses = snapshot.docs.map((doc) {
        return AddressModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> getOrders(String id) async {
    try {
      orders = null;

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('uuid', isEqualTo: id)
          .get();
      orders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {}
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      filteredCustomers = List.from(customers!);
    } else {
      filteredCustomers = customers!
          .where(
            (user) => user.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }
}
