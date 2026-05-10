import 'dart:io';
import 'dart:typed_data';

import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VendorService extends ChangeNotifier {
  VendorModel? vendor;
  List<ProductModel>? products;
  List<VendorModel>? vendors;
  List<OrderModel>? orders;

  Future<void> getVendorDetails(String id) async {
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
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }

  Future<void> gettVendors() async {
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

  Future<void> getOrders(String id) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendor_id', isEqualTo: id)
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

  Future<void> fetchProducts(String id) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('vendor_id', isEqualTo: id)
          .get();

      products = snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
      ;
      notifyListeners();
    } catch (e) {}
  }

  Uint8List? imageBytes;
  Uint8List? imageBytes2;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController secondNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();
  TextEditingController shopNameController = TextEditingController();
  TextEditingController shopAddressController = TextEditingController();

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> pickImage2() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes2 = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<String> uploadImageToStorage2(Uint8List imageData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'shop_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
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

  Future<String> uploadImageToStorage(Uint8List imageData) async {
    try {
      isLoading = true;
      notifyListeners();

      Reference storageRef = FirebaseStorage.instance.ref().child(
        'vendor_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
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

  Future<void> addVendor(BuildContext context) async {
    if (firstNameController.text.isEmpty) {
      showValidationDialog(context, "First Name cannot be empty.");
    } else if (secondNameController.text.isEmpty) {
      showValidationDialog(context, "Last Name cannot be empty.");
    } else if (phoneController.text.length < 10) {
      showValidationDialog(context, "Not Valid Phone Number");
    } else if (emailController.text.isEmpty) {
      showValidationDialog(context, "Email cannot be empty.");
    } else if (passwordController.text.length < 8) {
      showValidationDialog(context, "Please enter 8 digit password.");
    } else if (confirmController.text.trim() !=
        passwordController.text.trim()) {
      showValidationDialog(context, "Password Not Match");
    } else if (shopNameController.text.isEmpty) {
      showValidationDialog(context, "Shop Name cannot be empty.");
    } else if (shopAddressController.text.isEmpty) {
      showValidationDialog(context, "Shop Address cannot be empty.");
    } else if (imageBytes == null) {
      showValidationDialog(context, "vendor image cannot be empty.");
    } else if (imageBytes2 == null) {
      showValidationDialog(context, "Shop logo cannot be empty.");
    } else {
      String vendorImage = await uploadImageToStorage(imageBytes!);
      String shopImage = await uploadImageToStorage(imageBytes2!);
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('vendors')
          .add({
            "id": "",
            "first_name": firstNameController.text,
            "last_name": firstNameController.text,
            "phone": phoneController.text,
            "email": emailController.text,
            "password": passwordController.text,
            "shop_name": shopNameController.text,
            "shop_address": shopAddressController.text,
            "vendor_image": vendorImage,
            "shop_image": shopImage,
            "is_active": true,
          });
      String vendorId = docRef.id;

      await docRef.update({"id": vendorId});
      isLoading = false;
      showSuccessDialog(context);
      resetFields();

      notifyListeners();
    }
  }

  void resetFields() {
    firstNameController.clear();
    secondNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmController.clear();
    shopNameController.clear();
    shopAddressController.clear();

    imageBytes = null;
    imageBytes2 = null;

    notifyListeners();
  }

  void showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded corners
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Validation Error",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: Text("OK", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Success", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Vendor added successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> changeStatus(String id, bool value) async {
    await FirebaseFirestore.instance.collection('vendors').doc(id).update(
      {"is_active": value},
    );
    
    // Update local vendor if it matches
    if (vendor != null && vendor!.id == id) {
      vendor = VendorModel(
        id: vendor!.id,
        firstName: vendor!.firstName,
        lastName: vendor!.lastName,
        phone: vendor!.phone,
        email: vendor!.email,
        password: vendor!.password,
        shopName: vendor!.shopName,
        shopAddress: vendor!.shopAddress,
        vendorImage: vendor!.vendorImage,
        shopImage: vendor!.shopImage,
        isActive: value,
      );
    }
    
    // Update vendors list if it exists
    if (vendors != null) {
      vendors = vendors!.map((doc) {
        if (doc.id == id) {
          return VendorModel(
            id: doc.id,
            firstName: doc.firstName,
            lastName: doc.lastName,
            phone: doc.phone,
            email: doc.email,
            password: doc.password,
            shopName: doc.shopName,
            shopAddress: doc.shopAddress,
            vendorImage: doc.vendorImage,
            shopImage: doc.shopImage,
            isActive: value,
          );
        }
        return doc;
      }).toList();
    }
    
    notifyListeners();
  }
}
