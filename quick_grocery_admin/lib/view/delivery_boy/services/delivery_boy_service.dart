import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/realtime/firestore_sync_cache.dart';
import 'package:quick_grocery_admin/model/delivery_boy_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_grocery_admin/view/delivery_boy/domain/delivery_boy_order_stats.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/admin_delivery_client.dart';

class DeliveryBoyService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreSyncCache<DeliveryPersonModel> _deliveryCache =
      FirestoreSyncCache<DeliveryPersonModel>();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _deliverySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  AdminLiveSyncState deliverySyncState = const AdminLiveSyncState();
  String? deliveryLoadError;

  Map<String, DeliveryBoyOrderStats> _statsByRider = {};
  Map<String, List<Map<String, dynamic>>> _ordersByRider = {};
  bool _ordersStatsLoading = true;

  Uint8List? imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  List<DeliveryPersonModel>? deliveryBoys;

  DeliveryBoyService() {
    ensureDeliveryBoysListener();
    ensureOrderStatsListener();
  }

  bool get ordersStatsLoading => _ordersStatsLoading;

  DeliveryBoyOrderStats statsFor(String riderId) =>
      _statsByRider[riderId] ?? DeliveryBoyOrderStats.empty;

  List<Map<String, dynamic>> ordersFor(String riderId) =>
      List.unmodifiable(_ordersByRider[riderId] ?? const []);

  void ensureOrderStatsListener() {
    if (_ordersSub != null) return;
    _ordersStatsLoading = true;
    notifyListeners();

    _ordersSub = _db.collection('orders').snapshots().listen(
      (snap) {
        final docs =
            snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(growable: false);
        final result = DeliveryBoyOrderStatsAggregator.aggregate(docs);
        _statsByRider = result.statsByRider;
        _ordersByRider = result.ordersByRider;
        _ordersStatsLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[DeliveryBoyStats] orders stream error: $e');
        }
        _ordersStatsLoading = false;
        notifyListeners();
      },
    );
  }

  void ensureDeliveryBoysListener() {
    if (_deliverySub != null) return;
    deliverySyncState = deliverySyncState.copyWith(isLoading: true);
    notifyListeners();

    _deliverySub = _db.collection('delivery_boys').snapshots().listen(
      (snap) {
        _deliveryCache.applySnapshot(
          snap,
          (data, id) => DeliveryPersonModel.fromFirestore(data, id),
        );
        deliveryBoys = _deliveryCache.sorted(
          (a, b) => a.firstName.compareTo(b.firstName),
        );
        deliverySyncState = AdminLiveSyncState.fromSnapshotMetadata(
          snap.metadata,
          previous: deliverySyncState,
        );
        deliveryLoadError = null;
        notifyListeners();
      },
      onError: (Object e) {
        deliveryLoadError = e.toString();
        deliverySyncState = deliverySyncState.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: e.toString(),
        );
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _deliverySub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> getDeliveryBoys() async {
    ensureDeliveryBoysListener();
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

  final AdminDeliveryClient _adminDeliveryClient = AdminDeliveryClient();

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
      try {
        isLoading = true;
        notifyListeners();

        debugPrint('[DeliveryBoy] Creating delivery boy...');
        debugPrint('[DeliveryBoy] Uploading image...');
        final deliveryImage = await uploadImageToStorage(imageBytes!);
        if (deliveryImage.isEmpty) {
          throw Exception('Image upload failed. Check Firebase Storage rules.');
        }
        debugPrint('[DeliveryBoy] Image uploaded: $deliveryImage');

        debugPrint('[DeliveryBoy] Creating Firebase Auth + Firestore profile...');
        await _adminDeliveryClient.createDeliveryAccount(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: secondNameController.text.trim(),
          phone: phoneController.text.trim(),
          address: addressController.text.trim(),
          image: deliveryImage,
          licenceNumber: licenceController.text.trim(),
        );
        debugPrint('[DeliveryBoy] Success — delivery_boys updated (live listener).');

        if (context.mounted) {
          showSuccessDialog(context);
        }
        resetFields();
      } catch (e) {
        debugPrint('[DeliveryBoy] Error: $e');
        if (context.mounted) {
          final message = _formatError(e);
          showValidationDialog(context, message);
        }
      } finally {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  String _formatError(Object e) {
    var msg = e.toString();
    msg = msg.replaceFirst('Exception: ', '');
    msg = msg.replaceFirst('[firebase_functions/', '');
    if (msg.toLowerCase() == 'internal') {
      return 'Server error while creating delivery boy. '
          'Ensure Cloud Functions are deployed and you are signed in as admin.';
    }
    return msg;
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
          content: Text("Delivery Boy created successfully!"),
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
