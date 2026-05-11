/// Single canonical Firestore document for cross-app realtime pricing sync.
///
/// Admin writes here with [SetOptions.merge] alongside legacy collections.
/// User app listens to this document and applies overrides in [PricingService].
///
/// **Firestore rules (merge into your project rules):**
/// ```txt
/// match /settings/{document} {
///   allow read: if true;
///   allow write: if request.auth != null;
/// }
/// ```
abstract final class GlobalAppSettings {
  static const String collection = 'settings';
  static const String documentId = 'main';
}
