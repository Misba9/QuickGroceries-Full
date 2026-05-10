import 'dart:typed_data';

import 'package:quick_grocery_admin/model/delivery_boy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DeliveryBoyService extends ChangeNotifier {
  Uint8List? imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  List<DeliveryPersonModel>? deliveryBoys;

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> getDeliveryBoys() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .get();
      deliveryBoys = snapshot.docs.map((doc) {
        return DeliveryPersonModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching vendor: $e');
    }
  }

  Future<String> uploadImageToStorage(Uint8List imageData) async {
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

  TextEditingController firstNameController = TextEditingController();
  TextEditingController secondNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController licenceController = TextEditingController();

  void resetFields() {
    firstNameController.clear();
    secondNameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmController.clear();
    addressController.clear();
    licenceController.clear();
    imageBytes = null;

    notifyListeners();
  }

  void changeStatus(String id, bool value) async {
    for (var doc in deliveryBoys!) {
      if (doc.id == id) {
        doc.isActive = value;
        notifyListeners();
      }
    }
    await FirebaseFirestore.instance.collection('delivery_boys').doc(id).update(
      {"is_active": value},
    );
  }

  Future<void> addDeliveryBoy(BuildContext context) async {
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
    } else if (imageBytes == null) {
      showValidationDialog(context, "delivery boy image cannot be empty.");
    } else {
      String deliveryImage = await uploadImageToStorage(imageBytes!);

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .add({
            "id": "",
            "first_name": firstNameController.text,
            "last_name": secondNameController.text,
            "phone": phoneController.text,
            "createdDate": DateTime.now().toString(),
            "email": emailController.text,
            "password": passwordController.text,
            "address": addressController.text,
            "image": deliveryImage,
            "licence_number": licenceController.text,
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

  void showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Confirm Delete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this delivery boy? This action cannot be undone.",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: Text("Cancel", style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('delivery_boys')
                      .doc(id)
                      .delete();
                  
                  // Remove from local list
                  if (deliveryBoys != null) {
                    deliveryBoys!.removeWhere((doc) => doc.id == id);
                    notifyListeners();
                  }
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delivery boy deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting delivery boy: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
                child: Text("Delete", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        );
      },
    );
  }
}
