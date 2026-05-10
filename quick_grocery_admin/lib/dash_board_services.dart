import 'package:quick_grocery_admin/dabshboard.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashBoardServices extends ChangeNotifier {
  List<CustomerModel>? customers;
  List<VendorModel>? vendors;
  List<OrderModel>? orders;
  List<ProductModel>? products;
  List<RevenueData> revenueList = [];
  Map<String, int> monthlyRevenue = {};

  String totalRevenue = "0"; // Stores total revenue as a String

  Future<void> fetchRevenueData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('isDelivered', isEqualTo: true)
          .get();

      int total = 0; // Temporary total revenue variable

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Ensure 'created_date' exists
        if (data.containsKey('created_date')) {
          DateTime date;

          try {
            date = DateTime.parse(data['created_date']); // Parse from String
          } catch (e) {
            print("Invalid date format: ${data['created_date']}");
            continue; // Skip invalid date entries
          }

          String month = DateFormat(
            'MMM',
          ).format(date); // Convert to 'Jan', 'Feb', etc.

          // Calculate total from products
          double orderTotal = 0.0;
          if (data.containsKey('products') && data['products'] != null) {
            List<dynamic> products = data['products'];
            for (var product in products) {
              if (product is Map<String, dynamic>) {
                double price = (product['price'] ?? 0).toDouble();
                int itemCount = product['itemCount'] ?? 0;
                orderTotal += price * itemCount;
              }
            }
          }
          // Add delivery charge if available
          if (data.containsKey('delivery_charge')) {
            orderTotal += (data['delivery_charge'] ?? 0).toDouble();
          }

          int price = orderTotal.toInt();

          // Sum up revenue for each month
          monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + price;

          // Add to total revenue
          total += price;
        }
      }

      // Convert map to list of RevenueData for chart
      revenueList.clear();
      monthlyRevenue.forEach((month, revenue) {
        revenueList.add(RevenueData(month, revenue.toDouble()));
      });

      // Convert total revenue to String
      totalRevenue = total.toString();

      notifyListeners();
    } catch (e) {
      print("Error fetching revenue data: $e");
    }
  }

  Future<void> getVendors() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vendors')
          .get();
      vendors = snapshot.docs.map((doc) {
        return VendorModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }

  Future<void> getCustomers() async {
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
      orders = snapshot.docs.map((doc) {
        return OrderModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }

  Future<void> getProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      products = snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }
}
