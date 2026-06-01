import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';

/// Extended delivery partner profile (Firestore `delivery_boys/{id}`).
class DeliveryBoyProfile {
  const DeliveryBoyProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.image,
    required this.licence,
    required this.createdAt,
    required this.isActive,
    required this.isOnline,
    required this.pauseDeliveries,
    required this.walletBalance,
    required this.totalEarnings,
    required this.pendingPayout,
    required this.driverRating,
    required this.totalDeliveries,
    required this.completedOrders,
    required this.rejectedOrders,
    required this.incentivesTotal,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.bankAccountName,
    required this.bankAccountNumber,
    required this.bankIfsc,
    required this.upiId,
    required this.documents,
    required this.acceptanceRate,
    required this.onTimePercent,
    required this.availability,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String image;
  final String licence;
  final DateTime? createdAt;
  final bool isActive;
  final bool isOnline;
  final bool pauseDeliveries;
  final double walletBalance;
  final double totalEarnings;
  final double pendingPayout;
  final double driverRating;
  final int totalDeliveries;
  final int completedOrders;
  final int rejectedOrders;
  final double incentivesTotal;
  final String vehicleType;
  final String vehicleNumber;
  final String bankAccountName;
  final String bankAccountNumber;
  final String bankIfsc;
  final String upiId;
  final Map<String, DriverDocumentMeta> documents;
  final double acceptanceRate;
  final double onTimePercent;
  final DriverAvailability availability;

  bool get canReceiveOrders =>
      isActive && availability == DriverAvailability.online;

  factory DeliveryBoyProfile.fromFirestore(Map<String, dynamic> data, String id) {
    final docsRaw = data['documents'];
    final docs = <String, DriverDocumentMeta>{};
    if (docsRaw is Map) {
      docsRaw.forEach((key, value) {
        if (value is Map) {
          docs[key.toString()] = DriverDocumentMeta.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return DeliveryBoyProfile(
      id: data['id']?.toString() ?? id,
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      licence: data['licence']?.toString() ?? data['license']?.toString() ?? '',
      createdAt: _ts(data['createdAt']),
      isActive: data['is_active'] != false,
      isOnline: data['isOnline'] == true || data['online_status'] == true,
      pauseDeliveries: data['pause_deliveries'] == true,
      walletBalance: _dbl(data['wallet_balance']),
      totalEarnings: _dbl(data['total_earnings'] ?? data['total_amount']),
      pendingPayout: _dbl(data['pending_payout']),
      driverRating: _dbl(data['driver_rating'] ?? data['star']),
      totalDeliveries: _int(data['total_deliveries'] ?? data['total_orders']),
      completedOrders: _int(data['completed_orders']),
      rejectedOrders: _int(data['rejected_orders']),
      incentivesTotal: _dbl(data['incentives_total']),
      vehicleType: data['vehicle_type']?.toString() ?? '',
      vehicleNumber: data['vehicle_number']?.toString() ?? '',
      bankAccountName: data['bank_account_name']?.toString() ?? '',
      bankAccountNumber: data['bank_account_number']?.toString() ?? '',
      bankIfsc: data['bank_ifsc']?.toString() ?? '',
      upiId: data['upi_id']?.toString() ?? '',
      documents: docs,
      acceptanceRate: _dbl(data['acceptance_rate']),
      onTimePercent: _dbl(data['on_time_percent']),
      availability: _availabilityFrom(data),
    );
  }

  static DriverAvailability _availabilityFrom(Map<String, dynamic> data) {
    final raw = data['availability_status']?.toString().toLowerCase() ?? '';
    if (raw == 'online') return DriverAvailability.online;
    if (raw == 'paused') return DriverAvailability.paused;
    if (raw == 'offline') return DriverAvailability.offline;
    if (data['pause_deliveries'] == true) return DriverAvailability.paused;
    if (data['isOnline'] == true || data['online_status'] == true) {
      return DriverAvailability.online;
    }
    return DriverAvailability.offline;
  }

  Map<String, dynamic> toProfilePatch() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      if (image.isNotEmpty) 'image': image,
      'licence': licence,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'bank_ifsc': bankIfsc,
      'upi_id': upiId,
      'lastEdited': FieldValue.serverTimestamp(),
    };
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static int _int(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse(v?.toString() ?? '');
  }
}

class DriverDocumentMeta {
  const DriverDocumentMeta({
    required this.url,
    required this.status,
    this.uploadedAt,
  });

  final String url;
  final String status;
  final DateTime? uploadedAt;

  factory DriverDocumentMeta.fromMap(Map<String, dynamic> m) {
    DateTime? at;
    final ts = m['uploadedAt'];
    if (ts is Timestamp) at = ts.toDate();
    return DriverDocumentMeta(
      url: m['url']?.toString() ?? '',
      status: m['status']?.toString() ?? 'pending',
      uploadedAt: at,
    );
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'status': status,
        if (uploadedAt != null) 'uploadedAt': Timestamp.fromDate(uploadedAt!),
      };
}
