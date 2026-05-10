import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/home/screens/dabshboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DashBoardServices extends ChangeNotifier {
  List<CustomerModel>? customers;
  List<VendorModel>? vendors;
  List<OrderModel>? orders;
  List<ProductModel>? products;
  List<BannerModel>? banners;
  List<RevenueData> revenueList = [];
  Map<String, int> monthlyRevenue = {};
  Uint8List? imageBytes;
  Uint8List? videoBytes;
  String? videoPath;
  String bannerType = 'image'; // 'image' or 'video'
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String totalRevenue = "0"; // Stores total revenue as a String

  void setBannerType(String type) {
    bannerType = type;
    imageBytes = null;
    videoBytes = null;
    videoPath = null;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      videoPath = pickedFile.path;
      videoBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

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

  Future<void> fetchBanners() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('banners')
          .get();

      banners = snapshot.docs.map((doc) {
        return BannerModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteBanner(String id) async {
    FirebaseFirestore.instance.collection('banners').doc(id).delete();
    fetchBanners();
  }

  Future<String> uploadImageToStorage(Uint8List imageData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'banners/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      UploadTask uploadTask = storageRef.putData(imageData);
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> uploadVideoToStorage(Uint8List videoData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'banners/${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      UploadTask uploadTask = storageRef.putData(
        videoData,
        SettableMetadata(contentType: 'video/mp4'),
      );
      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return '';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBanner(BuildContext context) async {
    try {
      String imageUrl = '';
      String videoUrl = '';

      if (bannerType == 'image' && imageBytes != null) {
        imageUrl = await uploadImageToStorage(imageBytes!);
      } else if (bannerType == 'video' && videoBytes != null) {
        videoUrl = await uploadVideoToStorage(videoBytes!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image or video")),
        );
        return;
      }

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('banners')
          .add({
            "image": imageUrl,
            "video": videoUrl,
            "type": bannerType,
            "id": "",
            "created_date": DateTime.now().toString(),
          });
      await docRef.update({'id': docRef.id});

      // Reset after successful upload
      imageBytes = null;
      videoBytes = null;
      videoPath = null;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Banner Added Success")));
      fetchBanners();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error adding banner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding banner: ${e.toString()}")),
      );
    }
  }
}
