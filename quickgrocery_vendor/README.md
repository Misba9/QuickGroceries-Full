# quickgrocery_vendor
## Go to user app folder:

```bash
cd quickgrocery_vendor/  
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


Demo (if configured):

- Email: `vendor@test.com`
- Password: `vendor@123`
- Password: `test1234`

