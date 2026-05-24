import 'package:cloud_firestore/cloud_firestore.dart';

class VendorRequestModel {
  const VendorRequestModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.shopName,
    required this.shopAddress,
    required this.vendorImage,
    required this.shopLogo,
    required this.status,
    required this.isApproved,
    required this.isBlocked,
    this.authUid,
    this.createdAt,
    this.approvedAt,
    this.rejectionReason,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String shopName;
  final String shopAddress;
  final String vendorImage;
  final String shopLogo;
  final String status;
  final bool isApproved;
  final bool isBlocked;
  final String? authUid;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  String get fullName => '$firstName $lastName'.trim();

  factory VendorRequestModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return VendorRequestModel(
      id: id,
      firstName: data['firstName']?.toString() ?? data['first_name']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? data['last_name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      shopName: data['shopName']?.toString() ?? data['shop_name']?.toString() ?? '',
      shopAddress: data['shopAddress']?.toString() ?? data['shop_address']?.toString() ?? '',
      vendorImage: data['vendorImage']?.toString() ?? data['vendor_image']?.toString() ?? '',
      shopLogo: data['shopLogo']?.toString() ?? data['shop_image']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      isApproved: data['isApproved'] == true,
      isBlocked: data['isBlocked'] == true,
      authUid: data['authUid']?.toString(),
      createdAt: _toDate(data['createdAt']),
      approvedAt: _toDate(data['approvedAt']),
      rejectionReason: data['rejectionReason']?.toString(),
    );
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
