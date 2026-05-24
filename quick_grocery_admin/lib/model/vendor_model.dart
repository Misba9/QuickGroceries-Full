class VendorModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  final String shopName;
  final String shopAddress;
  final String vendorImage;
  final String shopImage;
  final bool isActive;
  final String? authUid;
  final bool authSynced;

  VendorModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
    required this.shopName,
    required this.shopAddress,
    required this.vendorImage,
    required this.shopImage,
    required this.isActive,
    this.authUid,
    this.authSynced = false,
  });

  /// Legacy vendors saved only in Firestore (auto ID) need Firebase Auth migration.
  bool get needsFirebaseAuthSync {
    if (authSynced) return false;
    final linked = authUid?.trim();
    if (linked == null || linked.isEmpty) return true;
    return linked != id;
  }

  factory VendorModel.fromFirestore(Map<String, dynamic> data, String id) {
    final storeName = data['shop_name']?.toString() ??
        data['storeName']?.toString() ??
        '';
    final firstName = data['first_name']?.toString() ??
        data['firstName']?.toString() ??
        data['ownerName']?.toString() ??
        '';

    return VendorModel(
      id: id,
      firstName: firstName,
      lastName: data['last_name']?.toString() ?? data['lastName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      shopName: storeName,
      shopAddress: data['shop_address']?.toString() ?? data['shopAddress']?.toString() ?? '',
      vendorImage: data['vendor_image']?.toString() ?? '',
      shopImage: data['shop_image']?.toString() ?? '',
      isActive: data['is_active'] == true || data['status']?.toString() == 'active',
      authUid: data['auth_uid']?.toString() ?? data['authUid']?.toString(),
      authSynced: data['authSynced'] == true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "email": email,
      "password": password,
      "shop_name": shopName,
      "shop_address": shopAddress,
      "vendor_image": vendorImage,
      "shop_image": shopImage,
      "is_active": isActive,
      if (authUid != null) "auth_uid": authUid,
      if (authSynced) "authSynced": true,
    };
  }
}
