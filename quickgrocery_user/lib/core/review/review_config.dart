/// Tunable knobs for the post-delivery "Rate Your Order" flow.
///
/// Change values here — or inject a custom [ReviewConfig] into
/// [OrderReviewService] — without touching dialog / persistence code.
class ReviewConfig {
  const ReviewConfig({
    this.promptDelay = const Duration(seconds: 4),
    this.laterReminder = const Duration(days: 3),
    this.storeReviewCooldown = const Duration(days: 30),
    this.highRatingThreshold = 4,
    this.enabled = true,
    this.androidPackageId = 'com.quickgrocery.io',
    this.iosBundleId = 'com.ahmed.quickgrocery',
    /// Numeric App Store id when known (used by [InAppReview.openStoreListing]).
    /// Leave empty to resolve via iTunes lookup by [iosBundleId].
    this.iosAppStoreId = '',
    this.playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.quickgrocery.io',
  });

  /// Wait after the Delivered UI settles before showing the prompt.
  final Duration promptDelay;

  /// Re-ask after the user taps "Later".
  final Duration laterReminder;

  /// Minimum gap between native Play / App Store review requests.
  final Duration storeReviewCooldown;

  /// Stars ≥ this value trigger the native in-app review API.
  final int highRatingThreshold;

  /// Kill-switch for the whole feature.
  final bool enabled;

  final String androidPackageId;
  final String iosBundleId;
  final String iosAppStoreId;
  final String playStoreUrl;

  static const ReviewConfig defaults = ReviewConfig();
}
