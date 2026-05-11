/// Emails that may sign into the admin panel **without** a matching Firestore
/// `admins` document (avoids lockout while Firestore is being set up).
///
/// All comparisons use lowercase.
const Set<String> kBootstrapAdminEmailsLowercase = {
  'admin@quickgroceries.in',
};

bool isBootstrapAdminEmail(String emailNormalizedLowercase) =>
    kBootstrapAdminEmailsLowercase.contains(emailNormalizedLowercase);
