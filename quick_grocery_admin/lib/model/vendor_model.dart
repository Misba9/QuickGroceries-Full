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
  final bool firebaseAuth;
  final String syncStatus;
  final String status;

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
    this.status = 'active',
    this.firebaseAuth = false,
    this.syncStatus = '',
  });

  String get ownerName => '$firstName $lastName'.trim();

  /// Display status: pending | approved | rejected | suspended | inactive | active
  String get displayStatus {
    if (status == 'suspended' || status == 'rejected') return status;
    if (status.isNotEmpty && status != 'active') return status;
    if (!isActive) return 'inactive';
    return 'approved';
  }

  bool get isSuspended =>
      status == 'suspended' || displayStatus == 'suspended';

  bool get isVendorActive =>
      !isSuspended && isActive && (status == 'active' || status == 'approved' || status.isEmpty);

  /// True when Firebase Auth is linked and vendor can log in at vendors/{uid}.
  bool get isAuthSyncedForLogin {
    if (syncStatus == 'synced' || firebaseAuth) return true;
    if (authSynced) return true;
    final linked = authUid?.trim();
    if (linked == null || linked.isEmpty) return false;
    return linked == id;
  }

  /// Legacy vendors saved only in Firestore (auto ID) need Firebase Auth migration.
  bool get needsFirebaseAuthSync => !isAuthSyncedForLogin;

  factory VendorModel.fromFirestore(Map<String, dynamic> data, String id) {
    final storeName = data['shop_name']?.toString() ??
        data['storeName']?.toString() ??
        data['shopName']?.toString() ??
        '';
    final firstName = data['first_name']?.toString() ??
        data['firstName']?.toString() ??
        data['ownerName']?.toString() ??
        '';

    final rawStatus = data['status']?.toString() ?? '';
    final isActive = data['is_active'] == true ||
        rawStatus == 'active' ||
        rawStatus == 'approved';
    final isBlocked = data['isBlocked'] == true || rawStatus == 'suspended';

    return VendorModel(
      id: id,
      firstName: firstName,
      lastName: data['last_name']?.toString() ?? data['lastName']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      shopName: storeName,
      shopAddress: data['shop_address']?.toString() ?? data['shopAddress']?.toString() ?? '',
      vendorImage: data['vendor_image']?.toString() ?? data['vendorImage']?.toString() ?? '',
      shopImage: data['shop_image']?.toString() ?? data['shopImage']?.toString() ?? data['shopLogo']?.toString() ?? '',
      isActive: isActive && !isBlocked,
      authUid: data['auth_uid']?.toString() ?? data['authUid']?.toString() ?? data['uid']?.toString(),
      authSynced: data['authSynced'] == true,
      firebaseAuth: data['firebaseAuth'] == true,
      syncStatus: data['syncStatus']?.toString() ?? '',
      status: isBlocked
          ? 'suspended'
          : (rawStatus.isNotEmpty ? rawStatus : (isActive ? 'approved' : 'inactive')),
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
      if (firebaseAuth) "firebaseAuth": true,
      if (syncStatus.isNotEmpty) "syncStatus": syncStatus,
      "status": status,
    };
  }
}
