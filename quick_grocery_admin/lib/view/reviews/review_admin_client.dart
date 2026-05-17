import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ReviewAdminClient {
  ReviewAdminClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: 'us-central1',
            );

  final FirebaseFunctions _fn;

  Future<void> _ensureAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Sign in required');
    }
  }

  Future<void> moderate({
    required String reviewId,
    required String action,
    String? adminReply,
  }) async {
    await _ensureAuth();
    await _fn.httpsCallable('moderateProductReview').call({
      'reviewId': reviewId,
      'action': action,
      if (adminReply != null) 'adminReply': adminReply,
    });
  }
}
