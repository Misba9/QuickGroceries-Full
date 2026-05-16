import 'package:quick_grocery_admin/view/auth/admin_bootstrap_emails.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/fcm_functions_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoginService extends ChangeNotifier {
  bool isLoading = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> signIn(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    try {
      final emailNormalized =
          emailController.text.trim().toLowerCase();
      // Firestore `admins` row OR bootstrap list (avoids lockout without that doc).
      final adminsSnap = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: emailNormalized)
          .limit(1)
          .get();
      final inAdminsTable = adminsSnap.docs.isNotEmpty;
      final bootstrapOk = isBootstrapAdminEmail(emailNormalized);

      if (kDebugMode) {
        debugPrint(
          '[Login] email=$emailNormalized inAdminsTable=$inAdminsTable '
          'bootstrapOk=$bootstrapOk',
        );
      }

      if (!inAdminsTable && !bootstrapOk) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Access Denied'),
            content: const Text(
              'You are not an admin. Please contact support.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailNormalized,
            password: passwordController.text,
          );
      if (userCredential.user != null) {
        final u = userCredential.user!;
        try {
          await FcmFunctionsClient().syncAdminClaimsFromAdmins();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('post-login syncAdminClaimsFromAdmins: $e');
          }
        }
        await u.getIdToken(true);
        if (kDebugMode) {
          final t = await u.getIdTokenResult(false);
          debugPrint(
            '[Login] uid=${u.uid} email=${u.email} claims=${t.claims}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LoginService.signIn: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
