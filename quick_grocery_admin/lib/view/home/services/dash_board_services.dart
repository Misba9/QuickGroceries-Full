import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/realtime/firestore_sync_cache.dart';
import 'package:quick_grocery_admin/core/realtime/product_catalog_metrics.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DashBoardServices extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<CustomerModel>? customers;
  List<VendorModel>? vendors;
  List<OrderModel>? orders;
  List<ProductModel>? products;
  List<BannerModel>? banners;
  bool bannersLoading = false;
  List<RevenueData> revenueList = [];
  Map<String, int> monthlyRevenue = {};
  Uint8List? imageBytes;
  Uint8List? videoBytes;
  Uint8List? thumbnailBytes;
  String? videoPath;
  String bannerType = 'image'; // 'image' or 'video'
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String totalRevenue = "0"; // Stores total revenue as a String

  AdminLiveSyncState dashboardSyncState = const AdminLiveSyncState();
  ProductCatalogMetrics productMetrics = ProductCatalogMetrics.empty;
  int categoriesCount = 0;
  String? dashboardError;

  bool _realtimeStarted = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _vendorsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bannersSub;

  final FirestoreSyncCache<ProductModel> _productsCache =
      FirestoreSyncCache<ProductModel>();
  final FirestoreSyncCache<VendorModel> _vendorsCache =
      FirestoreSyncCache<VendorModel>();
  final FirestoreSyncCache<CustomerModel> _customersCache =
      FirestoreSyncCache<CustomerModel>();
  final FirestoreSyncCache<OrderModel> _ordersCache =
      FirestoreSyncCache<OrderModel>();

  /// Starts all dashboard Firestore listeners (idempotent).
  void startRealtimeListeners() {
    if (_realtimeStarted) return;
    _realtimeStarted = true;
    dashboardSyncState = dashboardSyncState.copyWith(isLoading: true);
    notifyListeners();

    _productsSub = _db.collection('products').snapshots().listen(
      (snap) {
        _productsCache.applySnapshot(
          snap,
          (data, id) => ProductModel.fromFirestore(data, id),
        );
        products = _productsCache.sorted(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        productMetrics = ProductCatalogMetrics.fromProducts(products!);
        dashboardSyncState = AdminLiveSyncState.fromSnapshotMetadata(
          snap.metadata,
          previous: dashboardSyncState,
        );
        dashboardError = null;
        notifyListeners();
      },
      onError: _onDashboardStreamError,
    );

    _vendorsSub = _db.collection('vendors').snapshots().listen(
      (snap) {
        _vendorsCache.applySnapshot(
          snap,
          (data, id) => VendorModel.fromFirestore(data, id),
        );
        vendors = _vendorsCache.sorted(
          (a, b) => a.shopName.compareTo(b.shopName),
        );
        notifyListeners();
      },
      onError: _onDashboardStreamError,
    );

    _customersSub = _db.collection('customers').snapshots().listen(
      (snap) {
        _customersCache.applySnapshot(
          snap,
          (data, id) => CustomerModel.fromFirestore(data, id),
        );
        customers = _customersCache.values.toList();
        notifyListeners();
      },
      onError: _onDashboardStreamError,
    );

    _ordersSub = _db.collection('orders').snapshots().listen(
      (snap) {
        _ordersCache.applySnapshot(
          snap,
          (data, id) => OrderModel.fromFirestore(data, id),
        );
        orders = _ordersCache.values.toList();
        notifyListeners();
      },
      onError: _onDashboardStreamError,
    );

    _categoriesSub = _db.collection('categories').snapshots().listen(
      (snap) {
        categoriesCount = snap.docs.length;
        notifyListeners();
      },
      onError: _onDashboardStreamError,
    );

    bannersLoading = true;
    _bannersSub = _db.collection('banners').snapshots().listen(
      (snap) {
        banners = snap.docs
            .map((d) => BannerModel.fromFirestore(d.data(), d.id))
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
        bannersLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        bannersLoading = false;
        _onDashboardStreamError(e);
      },
    );
  }

  void _onDashboardStreamError(Object e) {
    dashboardError = e.toString();
    dashboardSyncState = dashboardSyncState.copyWith(
      isLoading: false,
      hasError: true,
      errorMessage: e.toString(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _vendorsSub?.cancel();
    _customersSub?.cancel();
    _ordersSub?.cancel();
    _categoriesSub?.cancel();
    _bannersSub?.cancel();
    super.dispose();
  }

  void setBannerType(String type) {
    bannerType = type;
    imageBytes = null;
    videoBytes = null;
    videoPath = null;
    thumbnailBytes = null;
    notifyListeners();
  }

  /// Clears picked media only (keeps banner type).
  void clearPickedMedia() {
    imageBytes = null;
    videoBytes = null;
    videoPath = null;
    thumbnailBytes = null;
    notifyListeners();
  }

  /// Resets form media and type to defaults.
  void resetBannerFormMedia() {
    bannerType = 'image';
    clearPickedMedia();
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

  Future<void> pickThumbnail() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      thumbnailBytes = await pickedFile.readAsBytes();
      notifyListeners();
    }
  }

  Future<void> fetchRevenueData() async {
    try {
      monthlyRevenue.clear();
      revenueList.clear();

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

  Future<void> getVendors() async => startRealtimeListeners();

  Future<void> getCustomers() async => startRealtimeListeners();

  Future<void> getOrders() async => startRealtimeListeners();

  Future<void> getProducts() async => startRealtimeListeners();

  Future<void> fetchBanners() async => startRealtimeListeners();

  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }

  Future<void> toggleBannerActive(String id, bool isActive) async {
    await _db.collection('banners').doc(id).update({'isActive': isActive});
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

  Future<void> addBanner(
    BuildContext context, {
    String title = '',
    String subtitle = '',
    String ctaText = 'Shop now',
    String redirectType = 'none',
    String redirectId = '',
    int priority = 10,
    bool isActive = true,
    bool showInHome = true,
    bool showInOffers = true,
    bool showAsPopup = false,
    bool autoplay = true,
    bool loop = true,
    bool muted = true,
    int popupAutoCloseSeconds = 12,
    String startsAtRaw = '',
    String endsAtRaw = '',
  }) async {
    try {
      String imageUrl = '';
      String videoUrl = '';
      String thumbnailUrl = '';

      if (bannerType == 'image' && imageBytes != null) {
        imageUrl = await uploadImageToStorage(imageBytes!);
      } else if (bannerType == 'video' && videoBytes != null) {
        videoUrl = await uploadVideoToStorage(videoBytes!);
        if (thumbnailBytes != null) {
          thumbnailUrl = await uploadImageToStorage(thumbnailBytes!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image or video")),
        );
        return;
      }

      final startsAt = DateTime.tryParse(startsAtRaw.trim());
      final endsAt = DateTime.tryParse(endsAtRaw.trim());

      final Map<String, dynamic> payload = {
        'image': imageUrl,
        'video': videoUrl,
        'videoUrl': videoUrl,
        'type': bannerType,
        'bannerType': bannerType,
        'thumbnailUrl': thumbnailUrl,
        'title': title,
        'subtitle': subtitle,
        'ctaText': ctaText,
        'redirectType': redirectType,
        'redirectId': redirectId,
        'isActive': isActive,
        'showInHome': showInHome,
        'showInOffers': showInOffers,
        'showAsPopup': showAsPopup,
        'priority': priority,
        'autoplay': autoplay,
        'loop': loop,
        'muted': muted,
        'popupAutoCloseSeconds': popupAutoCloseSeconds,
        'viewCount': 0,
        'clickCount': 0,
        'id': '',
        'created_date': DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (startsAt != null) {
        payload['startsAt'] = Timestamp.fromDate(startsAt);
      }
      if (endsAt != null) {
        payload['endsAt'] = Timestamp.fromDate(endsAt);
      }

      final docRef =
          await FirebaseFirestore.instance.collection('banners').add(payload);
      await docRef.update({'id': docRef.id});

      imageBytes = null;
      videoBytes = null;
      videoPath = null;
      thumbnailBytes = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner added successfully')),
        );
      }
      startRealtimeListeners();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error adding banner: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding banner: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> updateBanner(
    BuildContext context,
    String bannerId, {
    required String existingImageUrl,
    required String existingVideoUrl,
    required String existingThumbnailUrl,
    String title = '',
    String subtitle = '',
    String ctaText = 'Shop now',
    String redirectType = 'none',
    String redirectId = '',
    int priority = 10,
    bool isActive = true,
    bool showInHome = true,
    bool showInOffers = true,
    bool showAsPopup = false,
    bool autoplay = true,
    bool loop = true,
    bool muted = true,
    int popupAutoCloseSeconds = 12,
    String startsAtRaw = '',
    String endsAtRaw = '',
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      var imageUrl = existingImageUrl;
      var videoUrl = existingVideoUrl;
      var thumbnailUrl = existingThumbnailUrl;

      if (bannerType == 'image' && imageBytes != null) {
        imageUrl = await uploadImageToStorage(imageBytes!);
      } else if (bannerType == 'video' && videoBytes != null) {
        videoUrl = await uploadVideoToStorage(videoBytes!);
        if (thumbnailBytes != null) {
          thumbnailUrl = await uploadImageToStorage(thumbnailBytes!);
        }
      }

      final startsAt = DateTime.tryParse(startsAtRaw.trim());
      final endsAt = DateTime.tryParse(endsAtRaw.trim());

      final payload = <String, dynamic>{
        'image': imageUrl,
        'video': videoUrl,
        'videoUrl': videoUrl,
        'type': bannerType,
        'bannerType': bannerType,
        'thumbnailUrl': thumbnailUrl,
        'title': title,
        'subtitle': subtitle,
        'ctaText': ctaText,
        'redirectType': redirectType,
        'redirectId': redirectId,
        'isActive': isActive,
        'showInHome': showInHome,
        'showInOffers': showInOffers,
        'showAsPopup': showAsPopup,
        'priority': priority,
        'autoplay': autoplay,
        'loop': loop,
        'muted': muted,
        'popupAutoCloseSeconds': popupAutoCloseSeconds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (startsAt != null) {
        payload['startsAt'] = Timestamp.fromDate(startsAt);
      } else {
        payload['startsAt'] = FieldValue.delete();
      }
      if (endsAt != null) {
        payload['endsAt'] = Timestamp.fromDate(endsAt);
      } else {
        payload['endsAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('banners')
          .doc(bannerId)
          .update(payload);

      resetBannerFormMedia();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating banner: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating banner: $e')),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

/// Legacy monthly rollup for [fetchRevenueData] (kept for backward compatibility).
class RevenueData {
  final String month;
  final double revenue;
  RevenueData(this.month, this.revenue);
}
