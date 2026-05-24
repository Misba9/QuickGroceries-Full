# quickgrocery_vendor

## Run

```bash
flutter clean
flutter pub get
flutter run
```

## Vendor signup → approval → login

1. **Sign up** (Vendor app) → saves to `vendor_requests/` + pending flag (no Firebase Auth, no Cloud Functions).
2. **Admin** → Vendor → **Vendor Requests** → Approve / Reject / Delete.
3. **Approve** creates Firebase Auth + `vendors/{auth.uid}` with the same email/password from the request.
4. **Login** with that email/password after approval.

### Deploy rules (required once)

From `quick_grocery_admin/`:

```bash
firebase deploy --only firestore:rules,storage
```

## Login messages

| Case | Message |
|------|---------|
| Pending signup | Waiting for admin approval |
| Wrong password | Invalid password |
| No Auth account | Vendor account not approved yet |
| Blocked | Your account is blocked |

## Forgot password

`sendPasswordResetEmail` — only works after admin approval (Firebase Auth exists).

## Firebase Console

- Enable **Email/Password** authentication
- Project: `quikgroceries`
