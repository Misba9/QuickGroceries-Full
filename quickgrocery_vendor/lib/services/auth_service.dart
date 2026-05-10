import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';
import 'preference_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'vendors';

  /// Authenticate vendor by email and password
  /// Returns VendorModel if credentials are valid, null otherwise
  Future<VendorModel?> loginVendor(String email, String password) async {
    try {
      // Query Firestore for vendor with matching email
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // No vendor found with this email
      }

      final doc = querySnapshot.docs.first;
      final vendor = VendorModel.fromFirestore(doc.data(), doc.id);

      // Check if password matches
      if (vendor.password == password) {
        // Check if vendor is active
        if (vendor.isActive) {
          // Save vendor ID to SharedPreferences
          await PreferenceService.saveVendorId(vendor.id);
          return vendor;
        } else {
          throw Exception('Vendor account is inactive');
        }
      } else {
        return null; // Password doesn't match
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get vendor by ID
  Future<VendorModel?> getVendorById(String vendorId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(vendorId).get();
      if (doc.exists) {
        return VendorModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update vendor profile
  Future<void> updateVendor(VendorModel vendor) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(vendor.id)
          .update(vendor.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Logout vendor (clear SharedPreferences)
  Future<void> logout() async {
    await PreferenceService.clearVendorData();
  }
}

