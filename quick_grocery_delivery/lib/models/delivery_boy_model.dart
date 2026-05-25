import 'package:cloud_firestore/cloud_firestore.dart';

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

  static String _resolveName(Map<String, dynamic> data) {
    final direct = data['name']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final first = data['first_name']?.toString().trim() ?? '';
    final last = data['last_name']?.toString().trim() ?? '';
    return '$first $last'.trim();
  }

  static String _resolveCreatedDate(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.toDate().toIso8601String();
    }
    final legacy = data['createdDate'];
    if (legacy != null) return legacy.toString();
    return '';
  }

  static bool _resolveIsActive(Map<String, dynamic> data) {
    if (data.containsKey('isActive')) {
      return data['isActive'] == true;
    }
    return data['is_active'] != false;
  }

  factory DeliveryBoyModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DeliveryBoyModel(
      id: data['uid']?.toString() ?? data['id']?.toString() ?? id,
      name: _resolveName(data),
      image: data['image']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      licence: data['licence_number']?.toString() ??
          data['licence']?.toString() ??
          '',
      createdDate: _resolveCreatedDate(data),
      totalOrders: data['total_orders']?.toString() ?? '',
      totalEarnings: data['total_amount']?.toString() ?? '',
      isActive: _resolveIsActive(data),
    );
  }
}
