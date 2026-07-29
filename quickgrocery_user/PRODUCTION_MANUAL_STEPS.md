# Production release — manual steps (cannot be completed from code alone)

Complete these in order. Do **not** invent OAuth / APNs / Razorpay secret values.

---

## 1. GoogleService-Info.plist (REQUIRED)

### Current state
File: `quickgrocery_user/ios/Runner/GoogleService-Info.plist`

| Key | Status |
|-----|--------|
| `API_KEY` | Present |
| `GCM_SENDER_ID` | Present |
| `BUNDLE_ID` | Present (`com.ahmed.quickgrocery`) |
| `PROJECT_ID` | Present (`quikgroceries`) |
| `STORAGE_BUCKET` | Present |
| `GOOGLE_APP_ID` | Present |
| `CLIENT_ID` | **MISSING** |
| `REVERSED_CLIENT_ID` | **MISSING** |
| `DATABASE_URL` | Not required (Firestore only) |

`Info.plist` currently has only the encoded App ID URL scheme:
`app-1-970937777233-ios-10b9106006f6e0c66e0c70`

### Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/) → project **quikgroceries**
2. Project settings → Your apps → iOS app **com.ahmed.quickgrocery**
3. Download a fresh **GoogleService-Info.plist**
4. Confirm the downloaded file contains `CLIENT_ID` and `REVERSED_CLIENT_ID`
5. If those keys are still missing: enable **Google** as a Sign-in provider (even if unused) **or** add an iOS OAuth client under Google Cloud Console for this bundle ID, then re-download

### Replace in project
1. Replace `quickgrocery_user/ios/Runner/GoogleService-Info.plist` with the downloaded file
2. From `quickgrocery_user/`:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=quikgroceries --platforms=ios,android \
     --ios-bundle-id=com.ahmed.quickgrocery --yes
   ```
3. Confirm `lib/core/firebase/firebase_options.dart` now has `iosClientId`

### Info.plist URL scheme
After you have `REVERSED_CLIENT_ID` (example shape: `com.googleusercontent.apps.XXXX`):

Add a **second** `CFBundleURLTypes` entry in `ios/Runner/Info.plist`:

```xml
<dict>
  <key>CFBundleTypeRole</key>
  <string>Editor</string>
  <key>CFBundleURLName</key>
  <string>com.ahmed.quickgrocery.reversed-client</string>
  <key>CFBundleURLSchemes</key>
  <array>
    <string>PASTE_REVERSED_CLIENT_ID_HERE</string>
  </array>
</dict>
```

Keep the existing `app-1-970937777233-ios-…` scheme for Phone Auth reCAPTCHA return.

---

## 2. APNs production (REQUIRED)

### Code change applied
- Debug: `Runner/Runner.entitlements` → `aps-environment=development`
- Release/Profile: `Runner/RunnerRelease.entitlements` → `aps-environment=production`

### Apple Developer
1. Certificates, Identifiers & Profiles → **Keys** → create/upload APNs Auth Key (.p8)
2. Note **Key ID** + **Team ID** (`9Z4Q9DXTDW`)
3. Identifiers → App ID `com.ahmed.quickgrocery` → enable **Push Notifications**

### Firebase Console
1. Project settings → Cloud Messaging → Apple app config
2. Upload APNs Authentication Key (.p8) with Key ID + Team ID

### Xcode verify after Archive
```bash
# After Product → Archive, export or locate the .ipa / .app
codesign -d --entitlements :- path/to/Runner.app | grep aps-environment
# Expect: production
```

Capabilities checklist in Xcode → Runner → Signing & Capabilities:
- [ ] Push Notifications
- [ ] Background Modes → Remote notifications

---

## 3. Razorpay production deploy (REQUIRED)

Secrets must **never** be in the Flutter app (already removed).

```bash
cd "/Users/ahmed/Desktop/Quick Grocries/quick_grocery_admin"

# Set secrets (prompts for values from Razorpay Dashboard → API Keys)
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET

cd functions
npm run build

firebase deploy --only \
  functions:createRazorpayOrderCallable,\
  functions:placeOrderCallable,\
  functions:confirmRazorpayTipPaymentCallable
```

### Smoke test
1. Sign in on a physical device
2. Add items → Checkout → Online pay (use Razorpay test key first if available)
3. Confirm order appears with `paymentStatus=paid` and `razorpayPaymentId` set
4. Cancel payment mid-flow → order must **not** be created as paid
5. Replay same payment_id via crafted callable → must be rejected / deduped

Webhooks: optional enhancement; checkout signature verify is the primary gate already implemented.

---

## 4. Universal Links for referrals (REQUIRED for shared referral URLs)

Code now shares `https://www.quickgroceries.in/referral?code=…` (no Dynamic Links).

1. Host `apple-app-site-association` on `www.quickgroceries.in` (HTTPS, no redirects):
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [{
         "appID": "9Z4Q9DXTDW.com.ahmed.quickgrocery",
         "paths": ["/referral", "/referral/*"]
       }]
     }
   }
   ```
2. Xcode → Runner → Signing & Capabilities → **Associated Domains**
   - Add: `applinks:www.quickgroceries.in`
3. Android: add intent-filter for `https://www.quickgroceries.in/referral` in `AndroidManifest.xml` if not already present.

---

## 5. Crashlytics (code enabled — console verify)

1. Firebase Console → Crashlytics → enable for iOS app
2. After first TestFlight crash or non-fatal, confirm events appear
3. Upload dSYMs automatically via Xcode Archive / Flutter build

---

## 6. Firestore / Storage rules (RECOMMENDED)

Commit and deploy production rules that:
- Allow users to delete only their own `customers/{uid}`, `cart/{uid}`, `address` where `user_id==uid`
- Deny client writes setting `orders.isPaid` / `paymentStatus=paid`
- Deny client coupon create/delete

```bash
firebase deploy --only firestore:rules,storage
```

---

## 7. App Check enforcement (RECOMMENDED after attestation works)

1. Firebase Console → App Check → register iOS App Attest / DeviceCheck
2. Enforce for Auth, Firestore, Functions gradually
3. Then set `kFirebaseAppCheckEnforced = true` in `lib/core/firebase/app_check_providers.dart`
