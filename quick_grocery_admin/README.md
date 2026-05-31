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
firebase deploy --only functions:adminCreateVendorAccount,functions:adminRollbackVendorAuth,functions:adminSyncVendorAuthPassword,functions:adminMigrateVendorAuth,functions:adminRestoreVendorAuth,functions:adminMigrateVendorAuthHttp,functions:adminRestoreVendorAuthHttp,functions:adminApproveVendorRequest,functions:adminApproveVendorRequestHttp,functions:adminRejectVendorRequest,functions:adminRejectVendorRequestHttp,functions:submitVendorRequest,functions:adminBlockVendorFromRequest,functions:vendorCheckAuthForPasswordReset,functions:vendorDiagnoseLogin
```

### Restore vendor auth (e.g. Honey Traders)

1. Deploy functions above.
2. Admin → **Vendor List** → open **Auth recovery** (purple wrench) or use the orange **Honey Traders** banner.
3. Set a password (≥8 chars) → **Restore Firebase Auth**.
4. Vendor logs in on the vendor app with that email and password.
