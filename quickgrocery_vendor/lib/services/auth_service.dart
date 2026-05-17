import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/auth/partner_auth_api.dart';
import '../models/vendor_model.dart';
import 'preference_service.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PartnerAuthApi _partnerApi = PartnerAuthApi();
  final String _collectionName = 'vendors';

  /// Authenticate via Cloud Function (bcrypt, lockout, session).
  Future<VendorModel?> loginVendor(String email, String password) async {
    final result = await _partnerApi.login(email, password);
    if (result['success'] != true) {
      return null;
    }

    final partnerId = result['partnerId'] as String?;
    if (partnerId == null || partnerId.isEmpty) return null;

    final profile = result['profile'] as Map<String, dynamic>? ?? {};
    final vendor = VendorModel.fromFirestore(profile, partnerId);

    if (!vendor.isActive) {
      throw Exception('Vendor account is inactive');
    }

    final sessionVersion = (result['sessionVersion'] as num?)?.toInt() ?? 0;
    final forceChange = result['forcePasswordChange'] == true;

    await PreferenceService.saveVendorId(vendor.id);
    await PreferenceService.saveSessionVersion(sessionVersion);
    await PreferenceService.setForcePasswordChange(forceChange);

    return vendor;
  }

  Future<bool> shouldForcePasswordChange() =>
      PreferenceService.getForcePasswordChange();

  Future<bool> isSessionValid(String vendorId) async {
    final version = await PreferenceService.getSessionVersion();
    if (version == null) return true;
    final check = await _partnerApi.checkSession(
      partnerId: vendorId,
      sessionVersion: version,
    );
    return check['valid'] == true;
  }

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

  Future<void> updateVendor(VendorModel vendor) async {
    try {
      final data = vendor.toFirestore();
      data.remove('password');
      await _firestore.collection(_collectionName).doc(vendor.id).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await PreferenceService.clearVendorData();
  }
}
