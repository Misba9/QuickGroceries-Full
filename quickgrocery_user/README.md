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
flutter clean
flutter pub get
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

## Firebase Phone Auth (avoid external reCAPTCHA page)

Phone login uses **Firebase Phone Authentication**. On Android, SMS is sent after **native Play Integrity / SafetyNet** verification when the app is configured correctly. If SHA certificates are missing, Firebase falls back to an external **"Verify you're not a bot"** reCAPTCHA page — this is confusing and often fails.

### One-time Firebase Console setup

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

### Verify configuration

- Long-press the logo on the login screen (debug builds) → **Firebase Diagnostic**
- Logcat: `adb logcat | grep -E 'PhoneAuth|PhoneAuthFlow'`
- Expected when configured: `verification_method=native_play_integrity`
- Misconfigured builds show a clear login error instead of opening reCAPTCHA

### Debug SHA (this machine — confirm with signingReport)

| | |
|---|---|
| SHA-1 | `4F:A1:E2:DE:8E:EB:FC:28:9C:E0:08:2C:78:2D:6D:59:C9:64:4E:B3` |
| SHA-256 | `AB:48:9F:16:83:EF:71:5D:E7:C9:27:FC:B0:A7:7E:82:51:AF:81:75:51:60:24:45:86:B0:31:94:A2:0D:E6:41` |
