# quick_grocery_admin

Admin web panel for Quick Groceries.

**Live URL:** https://quikgroceries.web.app  
**Firebase project:** `quikgroceries`

## Run locally (web)

```bash
flutter pub get
flutter run -d chrome
```

## Deploy / update on Firebase (web)

From this folder:

```bash
flutter pub get
flutter build web --release
firebase deploy --only hosting
```

