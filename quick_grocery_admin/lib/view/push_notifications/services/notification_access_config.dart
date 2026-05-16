import 'package:quick_grocery_admin/view/auth/admin_bootstrap_emails.dart';

/// Optional extra admin emails (lowercase) for the push panel when Firestore
/// `admins` does not match (e.g. legacy data).
final Set<String> kNotificationAdminEmailAllowlist = {
  'admin@quickgrocery.com',
  ...kBootstrapAdminEmailsLowercase,
};

/// If true, any **signed-in** Firebase user can open the push UI (send still
/// requires Cloud Function auth). Set to `false` in production for tighter UI.
const bool kAllowNotificationPanelForAnySignedInUser = true;
