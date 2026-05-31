# quickgrocery_vendor

## Run

```bash
flutter clean
flutter pub get
flutter run
```
### Deploy rules (required once)

From `quick_grocery_admin/`:

```bash
firebase deploy --only firestore:rules,storage
```



## Forgot password

`sendPasswordResetEmail` — only works after admin approval (Firebase Auth exists).

## Firebase Console

- Enable **Email/

vendor@test.com

Password** authentication

vendor@123

- Project: `quikgroceries`
