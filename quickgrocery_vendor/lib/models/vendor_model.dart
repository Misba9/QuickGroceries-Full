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

  factory VendorModel.fromFirestore(Map<String, dynamic> data, String id) {
    return VendorModel(
      id: id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      shopName: data['shop_name'] ?? '',
      shopAddress: data['shop_address'] ?? '',
      vendorImage: data['vendor_image'] ?? '',
      shopImage: data['shop_image'] ?? '',
      isActive: data['is_active'] ?? false,
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
    };
  }
}
