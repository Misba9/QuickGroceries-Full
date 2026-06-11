# Quick Groceries

Firebase project: **quikgroceries**



## Deploy / update one app (web)

Run from each app folder, then deploy from **repo root**:

```bash
cd <app-folder>
flutter pub get
flutter build web --release
cd ..
firebase deploy --only hosting:<target> --project quikgroceries
```

| App | Folder | Deploy target |
|-----|--------|---------------|
| Admin | `quick_grocery_admin` | `hosting:admin` |
| User | `quickgrocery_user` | `hosting:user` |
| Vendor | `quickgrocery_vendor` | `hosting:vendor` |
| Delivery | `quick_grocery_delivery` | `hosting:delivery` |

**Example — update user app:**

```bash
cd quickgrocery_user
flutter pub get
flutter build web --release
cd ..
firebase deploy --only hosting:user --project quikgroceries
```

## Deploy all web apps

```bash
./scripts/deploy_hosting.sh
```

Builds all four apps and deploys every hosting target. Do **not** use `firebase deploy --only hosting` unless every app has a fresh `build/web` folder.

## Firestore indexes

```bash
cd quick_grocery_admin
firebase deploy --only firestore:indexes --project quikgroceries
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- Login: `firebase login`

Per-app details: see each app’s `README.md`.
