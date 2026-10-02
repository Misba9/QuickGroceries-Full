# Rate Your Order

Post-delivery experience review for the Quick Groceries **User** app
(Android + iOS).

## Behavior

1. Order reaches **Delivered**.
2. After ~4 seconds on the tracking screen (or when the user opens the app),
   show **Enjoyed your order?**
3. **Rate Now** → star picker.
   - **4–5 ★** → submit to backend, then Google Play In-App Review /
     `SKStoreReviewController` (throttled to once / 30 days).
   - **1–3 ★** → internal feedback form only (never store review).
4. **Later** → remind after 3 days (same order).
5. **No Thanks** → never ask again for that order.

## Architecture

| File | Role |
|------|------|
| `review_config.dart` | Delays, thresholds, store IDs |
| `review_preferences.dart` | Local: reviewed / dismissed / later / store cooldown |
| `store_review_service.dart` | `in_app_review` + Play / App Store fallback |
| `feedback_service.dart` | Callable `submitOrderExperienceReview` |
| `review_repository.dart` | Orchestrates prefs + API + store |
| `review_dialog.dart` | Material 3 / Cupertino UI |
| `review_service.dart` | When to show; safe-route deferral |
| `order_review_bootstrap.dart` | Landing + app-resume triggers |

## Backend

Callable: **`submitOrderExperienceReview`** (`us-central1`)

Writes:

- `order_reviews/{id}` — `{ orderId, userId, rating, review, platform, appVersion, createdAt, ... }`
- `orders/{orderId}` — `experience_rated`, `experience_rating`, `star`, `is_rated`

Deploy:

```bash
cd quick_grocery_admin/functions
npm run build
firebase deploy --only functions:submitOrderExperienceReview
```

## Local testing

1. Clear prefs for a clean slate (debug menu or wipe app data), or:

```dart
final prefs = await ReviewPreferences.create();
await prefs.clearAll();
```

2. Use a delivered order owned by the signed-in user.
3. Open Order Tracking — prompt appears after the delay.
4. Low rating → feedback sheet; high rating → native review (Play requires
   an install from Play; iOS may no-op under TestFlight quota).

### Fake versions / force paths

```dart
OrderReviewService.bindForTest(
  OrderReviewService.forTest(
    ReviewRepository(
      preferences: prefs,
      feedbackService: FeedbackService(),
      storeReviewService: StoreReviewService(),
      config: const ReviewConfig(
        promptDelay: Duration(milliseconds: 100),
        highRatingThreshold: 4,
        storeReviewCooldown: Duration.zero,
      ),
    ),
  ),
);
```

## Configuration

Edit `ReviewConfig` (or pass a custom instance into
`OrderReviewService.instance(config: ...)`):

- `promptDelay` — default 4s  
- `laterReminder` — default 3 days  
- `storeReviewCooldown` — default 30 days  
- `iosAppStoreId` — optional; empty uses iTunes lookup by bundle id  
- `enabled` — feature kill-switch  

## Safe screens

Prompts are deferred on `/otp`, `/login`, `/payment`, `/checkout`.
The delivered tracking screen uses `forceOnDeliveredScreen: true`.
