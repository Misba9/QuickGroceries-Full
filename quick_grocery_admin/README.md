# quick_grocery_admin

## Run (web)

```bash
flutter pub get
flutter run -d chrome
```
## deploy on firebase
```bash
flutter pub get 
flutter build web --release
firebase deploy --only hosting
```

Deploy rules:

```bash
firebase deploy --only firestore:rules,storage
```

### Deploy functions (required)

```bash
cd functions
npm run build
firebase deploy --only functions:adminCreateVendorAccount,functions:adminRollbackVendorAuth,functions:adminSyncVendorAuthPassword,functions:adminMigrateVendorAuth,functions:submitVendorRequest,functions:adminApproveVendorRequest,functions:adminRejectVendorRequest,functions:adminBlockVendorFromRequest,functions:vendorCheckAuthForPasswordReset,functions:vendorDiagnoseLogin
```
