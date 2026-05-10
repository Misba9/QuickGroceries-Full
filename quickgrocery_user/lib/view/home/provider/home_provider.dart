import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickgrocery/view/category/screens/main_category_view.dart'
    show MainCategoryViewScreen;
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/models/customer_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/screens/home_screen.dart';
import 'package:quickgrocery/view/orders/orders_screen.dart';
import 'package:quickgrocery/view/profile/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  CustomerModel? customer;
  bool isActive = true;
  LatLng currentLatLng = LatLng(0, 0);

  int get selectedIndex => _selectedIndex;
  List<ProductModel>? products;
  List<ProductModel>? todaysSnack;
  List<ProductModel>? priceDrop;
  List<ProductModel>? thisWeekSpecial;
  List<ProductModel>? beatyProduct;
  List<CategoryModel> categories = [];
  List<BannerModel> banners = [];
  String _address = 'Loading...';
  bool _isLoading = false;
  String get address => _address;

  void onSelectedChange(int i) {
    _selectedIndex = i;
    notifyListeners();
  }

  Future<void> getStatus() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc('4elRGQlC662hdcE1a1Ls')
          .get();
      var doc = snapshot.data() as Map<String, dynamic>;
      isActive = doc['isActive'];
      notifyListeners();
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> updateAdminFcmToken() async {
    try {
      // Get the FCM token
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        // Update it in Firestore
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcm_token': token});

        print('FCM token updated successfully: $token');
      } else {
        print('Failed to get FCM token.');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  ProductModel? getProductByName(String name) {
    try {
      return products!.firstWhere(
        (product) => product.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  List<Widget> pages = const [
    HomeScreen(),
    MainCategoryViewScreen(),
    OrdersScreeen(),
    ProfileScreen(),
  ];

  Future<void> fetchProducts() async {
    if (products == null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('products')
            .get();

        // Map Firestore documents to ProductModel list
        products = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ProductModel.fromFirestore(data, doc.id);
        }).toList();

        // Filter special categories
        todaysSnack = products!
            .where(
              (product) =>
                  product.specialCat.trim() == "Today's snacks deals".trim(),
            )
            .toList();

        priceDrop = products!
            .where((product) => product.specialCat == "Epic price drop items")
            .toList();

        thisWeekSpecial = products!
            .where((product) => product.specialCat == "Featured this week")
            .toList();
        beatyProduct = products!
            .where(
              (product) => product.specialCat == "Big deals on beauty products",
            )
            .toList();

        notifyListeners();
      } catch (e) {
        debugPrint("Error fetching products: $e");
      }
    }
  }

  // Force refresh products (clears cache)
  Future<void> refreshProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      // Map Firestore documents to ProductModel list
      products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProductModel.fromFirestore(data, doc.id);
      }).toList();

      // Filter special categories
      todaysSnack = products!
          .where(
            (product) =>
                product.specialCat.trim() == "Today's snacks deals".trim(),
          )
          .toList();

      priceDrop = products!
          .where((product) => product.specialCat == "Epic price drop items")
          .toList();

      thisWeekSpecial = products!
          .where((product) => product.specialCat == "Featured this week")
          .toList();
      beatyProduct = products!
          .where(
            (product) => product.specialCat == "Big deals on beauty products",
          )
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Error refreshing products: $e");
    }
  }

  // Refresh all home data
  Future<void> refreshAll() async {
    await Future.wait([
      refreshProducts(),
      refreshCategories(),
      refreshBanners(),
      getCustomer(),
      getStatus(),
    ]);
  }

  // Future<void> fetchMostSoldProducts() async {
  //   if (mostSoldProducts == null) {
  //     try {
  //       QuerySnapshot snapshot = await FirebaseFirestore.instance
  //           .collection('products')
  //           .where('most_sold', isEqualTo: true)
  //           .get();

  //       mostSoldProducts = snapshot.docs.map((doc) {
  //         return ProductModel.fromFirestore(
  //           doc.data() as Map<String, dynamic>,
  //           doc.id,
  //         );
  //       }).toList();
  //       notifyListeners();
  //     } catch (_) {}
  //   }
  // }

  Future<void> fetchCategories() async {
    if (categories.isEmpty) {
      await _loadCategoriesFromFirestore();
    }
  }

  /// Force refresh categories (clears cache).
  Future<void> refreshCategories() => _loadCategoriesFromFirestore();

  /// Loads every category in `categories/`, robust to missing `order`.
  ///
  /// Firestore's `orderBy('order')` silently drops docs without the field,
  /// which previously hid most categories. We do an unfiltered `.get()`
  /// and sort client-side so **all** categories show up — admin/legacy
  /// docs without `order` simply fall to the end.
  Future<void> _loadCategoriesFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      final fresh = <CategoryModel>[];
      for (final doc in snap.docs) {
        try {
          fresh.add(CategoryModel.fromFirestore(doc.data(), doc.id));
        } catch (e) {
          debugPrint('[HomeProvider] category parse fail ${doc.id}: $e');
        }
      }

      // Stable order: by `order` ascending, then by `name` for docs that
      // share the default 0 — keeps the grid deterministic.
      fresh.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      categories
        ..clear()
        ..addAll(fresh);
      notifyListeners();
      debugPrint('[HomeProvider] categories loaded: ${categories.length}');
    } catch (e) {
      debugPrint('[HomeProvider] error loading categories: $e');
    }
  }

  Future<void> fetchBanners() async {
    if (banners.isEmpty) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('banners')
            .get();

        for (var doc in querySnapshot.docs) {
          banners.add(
            BannerModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          );
        }
        notifyListeners();
        print('Categories fetched and sorted by order: $categories');
      } catch (e) {
        print('Error fetching categories: $e');
      }
    }
  }

  // Force refresh banners (clears cache)
  Future<void> refreshBanners() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('banners')
          .get();

      banners.clear();

      for (var doc in querySnapshot.docs) {
        banners.add(
          BannerModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id),
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error refreshing banners: $e');
    }
  }

  Future<void> getLocationAndAddress() async {
    _isLoading = true;

    try {
      // Request location permissio
      LocationPermission permission = await Geolocator.requestPermission();

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get the address from latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      currentLatLng = LatLng(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentLatLng = LatLng(position.latitude, position.longitude);
        _address = '${place.street}, ${place.locality}, ${place.country}';
        notifyListeners();
      }
    } catch (e) {
      _address = '$e';
    } finally {
      _isLoading = false;
    }
  }

  Future<void> getCustomer() async {
    if (customer == null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get();

        if (docSnapshot.exists) {
          customer = CustomerModel.fromFirestore(
            docSnapshot.data()!,
            docSnapshot.id,
          );
          // Store gender in SharedPreferences if available
          final data = docSnapshot.data()!;
          if (data.containsKey('gender')) {
            final pref = await SharedPreferences.getInstance();
            await pref.setString('user_gender', data['gender']);
          }
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> checkForForceUpdate(BuildContext context) async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: Duration(seconds: 10),
        minimumFetchInterval: Duration(seconds: 0), // For testing
      ),
    );
    await remoteConfig.fetchAndActivate();

    final requiredVersion = remoteConfig.getString('force_update_version');
    print("🔥 Force update version from Firebase: $requiredVersion");

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (_isVersionLower(currentVersion, requiredVersion)) {
      _showForceUpdateDialog(context);
    }
  }
}

bool _isVersionLower(String current, String required) {
  final currentParts = current.split('.').map(int.parse).toList();
  final requiredParts = required.split('.').map(int.parse).toList();
  print(currentParts);
  print(requiredParts);
  for (int i = 0; i < requiredParts.length; i++) {
    if (i >= currentParts.length || currentParts[i] < requiredParts[i]) {
      return true;
    } else if (currentParts[i] > requiredParts[i]) {
      return false;
    }
  }
  return false;
}

void _showForceUpdateDialog(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Update Required", style: TextStyle(color: AppColor.primary)),
      content: Text(
        "A new version of the app is available. Please update to continue.",
      ),
      actions: [
        TextButton(
          child: Text("Update Now", style: TextStyle(color: AppColor.primary)),
          onPressed: () {
            // Redirect to Play Store
            launchUrl(
              Uri.parse(
                "https://play.google.com/store/apps/details?id=com.siswar.app",
              ),
            );
          },
        ),
      ],
    ),
  );
}
