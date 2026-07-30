## Go to user app folder:

```bash
cd quickgrocery_user/  
```

## Run locally

```bash
flutter clean
flutter pub get
flutter run
```

## Build APK (Android)

```bash
flutter clean
flutter pub get
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`


## Build Android App Bundle (Play Store)

```bash
open ios/Runner.xcworkspace

flutter clean
flutter pub get 
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`


flutter build ipa

## Firebase Phone Auth (avoid external reCAPTCHA page)

Phone login uses **Firebase Phone Authentication**.

- **Android:** SMS after **native Play Integrity / SafetyNet** when SHA is registered. Missing SHA → external reCAPTCHA page.
- **iOS:** SMS after **silent APNs** verification when Push + APNs Auth Key are configured. Missing APNs key → Safari opens `*.firebaseapp.com` for reCAPTCHA (then returns to the app).

### Android — one-time Firebase Console setup

1. Print signing fingerprints:
   ```bash
   cd android && ./gradlew :app:signingReport
   ```
2. Firebase Console → **quikgroceries** → Project settings → Android app **com.quickgrocery.io** ("customer new")
3. Add **SHA-1** and **SHA-256** for every keystore you use (debug + release + Play App Signing)
4. **Download a fresh `google-services.json`** — the `oauth_client` array for `com.quickgrocery.io` must **not** be empty
5. Replace `android/app/google-services.json`, then:
   ```bash
   flutter clean && flutter pub get && flutter run
   ```
6. Enable **Phone** under Authentication → Sign-in method
7. (Optional) App Check → register debug token if enforcement is enabled

### iOS — one-time Apple + Firebase setup (required to stop Safari)

1. **Apple Developer** → Certificates, Identifiers & Profiles → **Keys** → **+**
   - Enable **Apple Push Notifications service (APNs)**
   - Download the `.p8` once; note **Key ID** and **Team ID** (`9Z4Q9DXTDW`)
2. **Identifiers** → App ID `com.ahmed.quickgrocery` → enable **Push Notifications**
3. **Firebase Console** → ⚙️ Project settings → **Cloud Messaging** → Apple app configuration → **Upload** the `.p8` (Key ID + Team ID)
4. Re-download **GoogleService-Info.plist** for iOS app `com.ahmed.quickgrocery` → replace `ios/Runner/GoogleService-Info.plist`
5. If the plist contains `REVERSED_CLIENT_ID`, add it as a URL Scheme in `ios/Runner/Info.plist` (in addition to the Encoded App ID scheme already present)
6. Xcode → Runner → Signing & Capabilities: **Push Notifications** + **Background Modes → Remote notifications**
7. Test on a **physical iPhone** (`flutter run` / Debug). Simulator always uses Safari reCAPTCHA.

Xcode console should show: `[PhoneAuth] APNs token registered with Firebase Auth`

### Verify configuration

- Long-press the logo on the login screen (debug builds) → **Firebase Diagnostic**
- Android Logcat: `adb logcat | grep -E 'PhoneAuth|PhoneAuthFlow'`
- iOS: Xcode console / `flutter logs` → filter `PhoneAuth`
- Expected: Android `verification_method=native_play_integrity` · iOS `verification_method=silent_apns`
- Misconfigured builds show a clear login error or open reCAPTCHA/Safari

### Debug SHA (this machine — confirm with signingReport)

| | |
|---|---|
| SHA-1 | `4F:A1:E2:DE:8E:EB:FC:28:9C:E0:08:2C:78:2D:6D:59:C9:64:4E:B3` |
| SHA-256 | `AB:48:9F:16:83:EF:71:5D:E7:C9:27:FC:B0:A7:7E:82:51:AF:81:75:51:60:24:45:86:B0:31:94:A2:0D:E6:41` |

## iOS startup performance

Cold start is intentionally slim:

1. **Before first frame:** Firebase init + SharedPreferences only
2. **After first frame (deferred):** App Check, Phone Auth settings, FCM/APNs/topics, `product_index` backfill
3. **Home paint:** disk cache → Landing immediately; banners/categories/featured refresh in background
4. **After home:** full product catalog, delivery zones, pricing streams, admin status/FCM token

Measure with Xcode console / `flutter logs` filtering `AppStartup`:

```bash
flutter run --release
# look for:
# [AppStartup] [N ms] runApp
# [AppStartup] [N ms] Guest/Auth bootstrap ready from cache
# [AppStartup] [N ms] Bootstrap complete
```

Typical improvement on a warm device with cache: first UI in ~1–2s instead of waiting on APNs (~6s) + full `products` collection + image precache.

## Rate Your Order

After delivery, the app asks customers to rate their experience (once per order).

- **4–5 stars** → native Play In-App Review / iOS `SKStoreReviewController` (max once / 30 days)
- **1–3 stars** → private feedback via Cloud Function `submitOrderExperienceReview`
- **Later** → remind after 3 days · **No Thanks** → never again for that order

Docs: [`lib/core/review/README.md`](lib/core/review/README.md)

Deploy the callable after pulling this change:

```bash
cd ../quick_grocery_admin/functions
firebase deploy --only functions:submitOrderExperienceReview
```

## In-App Updates

Remote Config parameter **`user_app_update`** (JSON). Docs:
[`lib/core/update/README.md`](lib/core/update/README.md)

Vendor / Delivery use `vendor_app_update` / `delivery_app_update`.
