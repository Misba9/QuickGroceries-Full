# Maintenance & Availability — Firestore Schema

Single document: **`app_config/maintenance`**

All four Flutter apps subscribe via `snapshots()` for realtime updates (no restart).

Admin panel: **Settings → Maintenance & Availability**  
User gate: `MaintenanceGate` on `LandingScreen`  
Vendor/Driver: `VendorMaintenanceGate` / `DriverMaintenanceGate`

---

## Example API / document JSON

```json
{
  "maintenance": true,
  "enabled": true,
  "mode": "soft",
  "affectedApps": {
    "user": true,
    "vendor": false,
    "driver": false,
    "admin": false
  },
  "title": {
    "en": "Quick Groceries Under Maintenance",
    "te": "క్విక్ గ్రోసరీస్ నిర్వహణలో",
    "hi": "क्विक ग्रोसरीज रखरखाव में",
    "ar": "كويك جروسريز تحت الصيانة"
  },
  "subtitle": {
    "en": "We'll be back soon"
  },
  "message": {
    "en": "We are upgrading servers"
  },
  "allowBrowsing": true,
  "allowOrders": false,
  "allowCart": false,
  "allowPayments": false,
  "reopenTime": "2026-05-21T08:00:00.000Z",
  "supportPhone": "+919999999999",
  "supportEmail": "support@quickgroceries.com",
  "showRetryButton": true,
  "showSupportButton": true,
  "lottieUrl": "https://assets.example.com/maintenance.json",
  "bannerImageUrl": "https://cdn.example.com/banner.jpg",
  "theme": "light",
  "schedule": {
    "enabled": true,
    "dailyOpenTime": "08:00",
    "dailyCloseTime": "22:00",
    "timezone": "Asia/Kolkata",
    "weeklyHolidays": [7],
    "festivalClosures": [
      { "start": "2026-12-25T00:00:00Z", "end": "2026-12-26T00:00:00Z", "reason": "Christmas" }
    ],
    "emergencyClose": false,
    "autoReopen": true
  },
  "areaAvailability": {
    "enabled": false,
    "disabledPincodes": ["500001"],
    "disabledCities": ["Hyderabad"],
    "disabledZoneIds": [],
    "maxDeliveryRadiusKm": 12
  },
  "driverSmartControl": {
    "enabled": true,
    "minDriversOnline": 2,
    "autoPauseCod": true,
    "limitOrderDistanceKm": 8,
    "pauseOrdering": true,
    "highDemandMessage": { "en": "High demand — please try again shortly" }
  },
  "emergencyControls": {
    "stopAllOrders": false,
    "disablePayments": false,
    "disableCod": false,
    "disableRegistrations": false,
    "disableGuestCheckout": false
  },
  "engagement": {
    "showCoupons": true,
    "showOffers": true,
    "showReferral": true,
    "showComingSoon": false,
    "couponCodes": ["SAVE10"],
    "offerHeadline": "Flat 10% when we reopen"
  },
  "legacyStoreActive": true,
  "updatedAt": "<server timestamp>",
  "updatedBy": "<admin uid>"
}
```

---

## Maintenance modes

| `mode`       | User behaviour                                      |
| ------------ | --------------------------------------------------- |
| `soft`       | Browse catalog; orders/cart/checkout blocked        |
| `hard`       | Full-screen maintenance block                       |
| `read_only`  | Products visible; cart and payment disabled         |

Schedule + emergency close + legacy `admins/{id}.isActive` are evaluated in `MaintenanceEvaluator`.

---

## Logs

Collection: **`maintenance_logs/{autoId}`**

Written on admin save / emergency toggles:

```json
{
  "action": "admin_save",
  "config": { },
  "createdAt": "<timestamp>",
  "adminUid": "<uid>"
}
```

---

## Vendor availability (per vendor)

Extend **`vendors/{vendorId}`** (admin + vendor app):

```json
{
  "pauseOrders": false,
  "unavailableUntil": "2026-05-22T14:00:00Z",
  "lunchBreakStart": "13:00",
  "lunchBreakEnd": "14:00",
  "vacationStart": null,
  "vacationEnd": null,
  "adminOverridePause": false
}
```

---

## Push notifications

Cloud Function: `onMaintenanceConfigChange` — sends FCM topic messages when `enabled` or schedule state changes (`user_app`, `vendor_app`, `driver_app` topics).

---

## Flutter layout (user app)

```
lib/maintenance/
  data/maintenance_repository.dart
  domain/maintenance_config.dart
  domain/maintenance_evaluator.dart
  domain/maintenance_status.dart
  presentation/providers/maintenance_providers.dart
  presentation/screens/maintenance_screen.dart
  presentation/widgets/maintenance_gate.dart
  presentation/widgets/maintenance_countdown.dart
  presentation/widgets/maintenance_engagement_section.dart
```
