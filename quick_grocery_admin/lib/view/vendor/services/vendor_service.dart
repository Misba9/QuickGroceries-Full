import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:quick_grocery_admin/model/address_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_grocery_admin/view/vendor/models/vendor_profile_stats.dart';
import 'package:quick_grocery_admin/view/vendor/services/admin_vendor_client.dart';
import 'package:quick_grocery_admin/view/vendor/utils/vendor_order_utils.dart';

class VendorService extends ChangeNotifier {
  VendorModel? vendor;
  List<ProductModel>? products;
  List<VendorModel>? vendors;
  List<OrderModel>? orders;
  String? loadError;
  bool vendorsLoading = true;
  String vendorSearch = '';
  String vendorStatusFilter = 'all';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _vendorsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productCountsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _orderCountsSub;
  final Map<String, int> vendorProductCounts = {};
  final Map<String, int> vendorOrderCounts = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileVendorSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _profileProductsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _profileOrdersSub;
  String? _profileVendorId;
  bool profileLoading = false;
  String? profileError;
  bool profileOrdersLoading = false;

  VendorService() {
    _watchVendors();
    _watchListAggregates();
  }

  void _watchListAggregates() {
    _productCountsSub?.cancel();
    _productCountsSub = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen((snap) {
      vendorProductCounts.clear();
      for (final d in snap.docs) {
        final vid = d.data()['vendor_id']?.toString() ?? '';
        if (vid.isEmpty) continue;
        vendorProductCounts[vid] = (vendorProductCounts[vid] ?? 0) + 1;
      }
      notifyListeners();
    });

    _orderCountsSub?.cancel();
    _orderCountsSub = FirebaseFirestore.instance
        .collection('orders')
        .limit(800)
        .snapshots()
        .listen((snap) {
      vendorOrderCounts.clear();
      for (final d in snap.docs) {
        final data = d.data();
        final ids = <String>{};
        final products = data['products'];
        if (products is List) {
          for (final raw in products) {
            if (raw is Map) {
              final vid = raw['vendor_id']?.toString() ?? raw['vendorId']?.toString() ?? '';
              if (vid.isNotEmpty) ids.add(vid);
            }
          }
        }
        final top = data['vendor_id']?.toString() ?? data['vendorId']?.toString();
        if (top != null && top.isNotEmpty) ids.add(top);
        for (final vid in ids) {
          vendorOrderCounts[vid] = (vendorOrderCounts[vid] ?? 0) + 1;
        }
      }
      notifyListeners();
    });
  }

  int productCountFor(String vendorId) => vendorProductCounts[vendorId] ?? 0;

  int orderCountFor(String vendorId) => vendorOrderCounts[vendorId] ?? 0;

  void _watchVendors() {
    _vendorsSub?.cancel();
    vendorsLoading = true;
    notifyListeners();
    _vendorsSub = FirebaseFirestore.instance
        .collection('vendors')
        .snapshots()
        .handleError((Object e) {
      if (kDebugMode) debugPrint('[VendorService] stream error: $e');
      loadError = e.toString();
      vendorsLoading = false;
      notifyListeners();
    }).listen((snap) {
      vendors = snap.docs
          .map((d) => VendorModel.fromFirestore(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.shopName.compareTo(b.shopName));
      vendorsLoading = false;
      loadError = null;
      notifyListeners();
    });
  }

  List<VendorModel> get filteredVendors {
    final all = vendors ?? [];
    var list = all;
    if (vendorStatusFilter != 'all') {
      list = list
          .where((v) => v.displayStatus == vendorStatusFilter)
          .toList();
    }
    final q = vendorSearch.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list
        .where(
          (v) =>
              v.shopName.toLowerCase().contains(q) ||
              v.ownerName.toLowerCase().contains(q) ||
              v.email.toLowerCase().contains(q) ||
              v.phone.contains(q),
        )
        .toList();
  }

  void setVendorSearch(String q) {
    vendorSearch = q;
    notifyListeners();
  }

  void setVendorStatusFilter(String status) {
    vendorStatusFilter = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _vendorsSub?.cancel();
    _productCountsSub?.cancel();
    _orderCountsSub?.cancel();
    stopWatchingVendorProfile();
    super.dispose();
  }

  VendorProfileStats get profileStats => VendorProfileStats.from(
        products: products ?? [],
        orders: orders ?? [],
      );

  /// Real-time vendor profile: doc + products + orders (filtered by line items).
  void watchVendorProfile(String vendorId) {
    if (_profileVendorId == vendorId &&
        _profileVendorSub != null &&
        _profileProductsSub != null) {
      return;
    }
    stopWatchingVendorProfile();
    _profileVendorId = vendorId;
    profileLoading = true;
    profileOrdersLoading = true;
    profileError = null;
    vendor = null;
    products = null;
    orders = null;
    notifyListeners();

    if (kDebugMode) {
      debugPrint('[VendorService] watchVendorProfile id=$vendorId');
    }

    _profileVendorSub = FirebaseFirestore.instance
        .collection('vendors')
        .doc(vendorId)
        .snapshots()
        .listen(
      (snap) {
        if (!snap.exists) {
          vendor = null;
          profileError = 'Vendor not found';
        } else {
          vendor = VendorModel.fromFirestore(snap.data()!, snap.id);
          profileError = null;
        }
        profileLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[VendorService] vendor snapshot: $e');
        profileError = e.toString();
        profileLoading = false;
        notifyListeners();
      },
    );

    _profileProductsSub = FirebaseFirestore.instance
        .collection('products')
        .where('vendor_id', isEqualTo: vendorId)
        .snapshots()
        .listen(
      (snap) {
        products = snap.docs
            .map((d) => ProductModel.fromFirestore(d.data(), d.id))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[VendorService] products snapshot: $e');
      },
    );

    _watchVendorOrders(vendorId);
  }

  void _watchVendorOrders(String vendorId) {
    _profileOrdersSub?.cancel();
    _profileOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .limit(500)
        .snapshots()
        .listen(
      (snap) {
        orders = snap.docs
            .where((d) => VendorOrderUtils.belongsToVendorData(d.data(), vendorId))
            .map((d) => OrderModel.fromFirestore(d.data(), d.id))
            .toList();
        profileOrdersLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[VendorService] orders orderBy failed, fallback: $e');
        }
        _watchVendorOrdersFallback(vendorId);
      },
    );
  }

  void _watchVendorOrdersFallback(String vendorId) {
    _profileOrdersSub?.cancel();
    _profileOrdersSub = FirebaseFirestore.instance
        .collection('orders')
        .limit(500)
        .snapshots()
        .listen(
      (snap) {
        orders = snap.docs
            .where((d) => VendorOrderUtils.belongsToVendorData(d.data(), vendorId))
            .map((d) => OrderModel.fromFirestore(d.data(), d.id))
            .toList()
          ..sort((a, b) {
            final da = VendorOrderUtils.parseCreatedDate(a.createdDate);
            final db = VendorOrderUtils.parseCreatedDate(b.createdDate);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return db.compareTo(da);
          });
        profileOrdersLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        if (kDebugMode) debugPrint('[VendorService] orders fallback: $e');
        profileOrdersLoading = false;
        profileError ??= 'Could not load orders';
        notifyListeners();
      },
    );
  }

  void stopWatchingVendorProfile() {
    _profileVendorSub?.cancel();
    _profileProductsSub?.cancel();
    _profileOrdersSub?.cancel();
    _profileVendorSub = null;
    _profileProductsSub = null;
    _profileOrdersSub = null;
    _profileVendorId = null;
    profileLoading = false;
    profileOrdersLoading = false;
  }

  Future<void> gettVendors() async {
    vendorsLoading = vendors == null;
    notifyListeners();
  }

  Future<void> getVendorDetails(String id) async {
    watchVendorProfile(id);
  }

  @Deprecated('Use watchVendorProfile for real-time orders')
  Future<void> getOrders(String id) async {
    watchVendorProfile(id);
  }

  @Deprecated('Use watchVendorProfile for real-time products')
  Future<void> fetchProducts(String id) async {
    watchVendorProfile(id);
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

  final AdminVendorClient _adminVendorClient = AdminVendorClient();

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
    } else if (confirmController.text != passwordController.text) {
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
      try {
        isLoading = true;
        notifyListeners();

        final vendorImage = await uploadImageToStorage(imageBytes!);
        final shopImage = await uploadImageToStorage(imageBytes2!);

        final result = await _adminVendorClient.createVendorAccount(
          email: emailController.text.trim(),
          password: passwordController.text,
          firstName: firstNameController.text.trim(),
          lastName: secondNameController.text.trim(),
          storeName: shopNameController.text.trim(),
          phone: phoneController.text.trim(),
          shopAddress: shopAddressController.text.trim(),
          vendorImage: vendorImage,
          shopImage: shopImage,
        );

        if (context.mounted) {
          final uid = result['authUid']?.toString() ?? result['vendorId']?.toString() ?? '';
          showSuccessDialog(context, vendorUid: uid);
        }
        resetFields();
      } catch (e) {
        if (context.mounted) {
          showErrorDialog(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      } finally {
        isLoading = false;
        notifyListeners();
      }
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
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'Validation Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    if (kDebugMode) debugPrint('[VendorService] error: $message');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text(
                'Vendor Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(
    BuildContext context, {
    String vendorUid = '',
    String? message,
  }) {
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
          content: Text(
            message ??
                (vendorUid.isEmpty
                    ? "Vendor added successfully!"
                    : "Vendor added successfully!\nFirebase UID: $vendorUid\nFirestore: vendors/$vendorUid"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  VendorModel? findVendorByShopName(String shopName) {
    final q = shopName.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final v in vendors ?? []) {
      if (v.shopName.trim().toLowerCase() == q) return v;
    }
    return null;
  }

  Future<void> migrateVendorAuth(
    BuildContext context, {
    required String vendorDocId,
    required String password,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[VendorService] sync start id=$vendorDocId');
      }
      final result = await _adminVendorClient.migrateVendorAuth(
        vendorDocId: vendorDocId,
        password: password,
      );
      if (!context.mounted) return;
      final uid = result['authUid']?.toString() ?? '';
      final linked = result['linkedExistingAuth'] == true;
      final msg = uid.isEmpty
          ? 'Vendor synced with Firebase Auth.'
          : linked
              ? 'Linked existing Firebase Auth.\nUID: $uid\nPath: vendors/$uid'
              : 'Firebase Auth created.\nUID: $uid\nPath: vendors/$uid\n'
                  'Share the password with the vendor for login.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreVendorAuth(
    BuildContext context, {
    String? vendorDocId,
    String? shopName,
    required String password,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[VendorService] restore shop=$shopName id=$vendorDocId');
      }
      final result = await _adminVendorClient.restoreVendorAuth(
        vendorDocId: vendorDocId,
        shopName: shopName,
        password: password,
      );
      if (!context.mounted) return;
      final uid = result['authUid']?.toString() ?? '';
      final msg =
          'Vendor restored.\nUID: $uid\nLogin enabled at vendors/$uid';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700),
      );
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetVendorPassword(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      notifyListeners();
      await _adminVendorClient.syncAuthPassword(email: email, password: password);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor password updated in Firebase Auth.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVendorStatus(String id, String status) async {
    final isActive = status == 'approved' || status == 'active';
    final suspended = status == 'suspended';
    await FirebaseFirestore.instance.collection('vendors').doc(id).update({
      'status': status,
      'is_active': isActive && !suspended,
      'isActive': isActive && !suspended,
      'isBlocked': suspended || status == 'rejected',
      'isApproved': status == 'approved' || status == 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (kDebugMode) {
      debugPrint('[VendorService] status updated id=$id status=$status');
    }
    notifyListeners();
  }

  Future<void> suspendVendor(String id) => updateVendorStatus(id, 'suspended');

  Future<void> activateVendor(String id) => updateVendorStatus(id, 'active');

  Future<void> changeStatus(String id, bool active) async {
    await updateVendorStatus(id, active ? 'active' : 'suspended');
  }

  /// Delete vendor when no products and no active orders.
  Future<void> deleteVendor(BuildContext context, String id) async {
    final productList = products ?? [];
    final orderList = orders ?? [];
    final activeOrders =
        orderList.where(VendorOrderUtils.isActiveOrder).length;

    if (productList.isNotEmpty) {
      throw Exception(
        'Cannot delete: vendor has ${productList.length} product(s). Remove all products first.',
      );
    }
    if (activeOrders > 0) {
      throw Exception(
        'Cannot delete: vendor has $activeOrders active order(s). Wait until orders complete or cancel them.',
      );
    }

    final v = vendor;
    final authUid = v?.authUid?.trim().isNotEmpty == true
        ? v!.authUid!
        : (v?.isAuthSyncedForLogin == true ? v!.id : null);

    await FirebaseFirestore.instance.collection('vendors').doc(id).delete();
    if (kDebugMode) debugPrint('[VendorService] deleted vendor doc id=$id');

    if (authUid != null && authUid.isNotEmpty) {
      try {
        await _adminVendorClient.rollbackVendorAuth(authUid);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[VendorService] auth rollback skipped: $e');
        }
      }
    }

    stopWatchingVendorProfile();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor deleted successfully.')),
      );
      Navigator.of(context).pop();
    }
  }
}
