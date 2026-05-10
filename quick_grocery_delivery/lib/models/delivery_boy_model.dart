class DeliveryBoyModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String password;
  final String licence;
  final String createdDate;
  final String image;
  final String totalOrders;
  final String totalEarnings;
  final bool isActive;

  DeliveryBoyModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.password,
    required this.licence,
    required this.createdDate,
    required this.id,
    required this.image,
    required this.totalOrders,
    required this.totalEarnings,
    required this.isActive,
  });

  factory DeliveryBoyModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DeliveryBoyModel(
      id: data['id'] ?? "",
      name: data['name'] ?? "",
      image: data['image'] ?? "",
      phone: data['phone'] ?? '',
      email: data['email'] ?? "",
      address: data['address'] ?? "",
      password: data['password'] ?? "",
      licence: data['licence'] ?? "",
      createdDate: data['createdAt'].toString() ?? "",
      totalOrders: data['total_orders'].toString() ?? "",
      totalEarnings: data['total_amount'].toString() ?? "",
      isActive: data['is_active'] ?? true,
    );
  }
}
