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
  });

  /// Matches Cloud Function `publicProfile`: active unless explicitly false.
  static bool parseIsActive(Map<String, dynamic> data) {
    return data['is_active'] != false;
  }

  static bool parseIsBlocked(Map<String, dynamic> data) {
    return data['isBlocked'] == true || data['is_blocked'] == true;
  }

  static bool parseIsApproved(Map<String, dynamic> data) {
    if (data.containsKey('isApproved')) {
      return data['isApproved'] == true;
    }
    if (data.containsKey('is_approved')) {
      return data['is_approved'] == true;
    }
    // Legacy admin-created vendors without approval fields are treated as approved.
    return true;
  }

  /// Returns a user-facing message when login must be blocked, or null if OK.
  static String? loginBlockedReason(Map<String, dynamic> data) {
    if (parseIsBlocked(data)) {
      return 'Your account is blocked';
    }
    if (!parseIsApproved(data)) {
      return 'Waiting for admin approval';
    }
    if (!parseIsActive(data)) {
      return 'Your vendor account is inactive. Contact support to activate it.';
    }

    if (data.containsKey('status')) {
      final status = data['status'].toString().trim().toLowerCase();
      if (status == 'pending') {
        return 'Waiting for admin approval';
      }
      if (status != 'active') {
        return 'Your vendor account is not active.';
      }
    }

    return null;
  }

  factory VendorModel.fromFirestore(Map<String, dynamic> data, String id) {
    final ownerName = data['ownerName']?.toString() ?? '';
    final storeName = data['storeName']?.toString() ?? '';
    final firstName = data['firstName']?.toString() ??
        data['first_name']?.toString() ??
        ownerName;
    final lastName = data['lastName']?.toString() ??
        data['last_name']?.toString() ??
        '';
    final shopName = data['shopName']?.toString() ??
        data['shop_name']?.toString() ??
        storeName;
    final shopAddress = data['shopAddress']?.toString() ??
        data['shop_address']?.toString() ??
        '';
    final vendorImage = data['vendorImage']?.toString() ??
        data['vendor_image']?.toString() ??
        '';
    final shopImage = data['shopLogo']?.toString() ??
        data['shop_image']?.toString() ??
        '';

    return VendorModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      shopName: shopName,
      shopAddress: shopAddress,
      vendorImage: vendorImage,
      shopImage: shopImage,
      isActive: parseIsActive(data),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'email': email,
      'ownerName': firstName,
      'storeName': shopName,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'vendor_image': vendorImage,
      'shop_image': shopImage,
      'is_active': isActive,
    };
  }
}
