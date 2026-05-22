# Realtime contract — Quick Grocery (User / Admin / Vendor / Delivery)

This document is the **single source of truth** for the Firestore schema
shared by the four apps in this workspace:

* `quickgrocery_user` — customer app (this repo's realtime backbone)
* `quick_grocery_admin` — admin panel
* `quickgrocery_vendor` — vendor app
* `quick_grocery_delivery` — delivery rider app

All four apps **read and write the same Firestore documents**. Whenever
any app changes a document, every other app subscribed to that path
gets a snapshot tick within ~ms — no manual refresh.

> Security rules are intentionally out of scope for this commit (per
> the user's choice). Add role-based rules using Firebase Auth custom
> claims before going to production.

---

## 1. Collections at a glance

| Collection                       | Owner / Writer                             | Subscribed by                  |
| -------------------------------- | ------------------------------------------ | ------------------------------ |
| `products/{id}`                  | Admin (create/update), Vendor (stock/price) | User, Admin, Vendor            |
| `categories/{id}`                | Admin                                      | User, Admin, Vendor            |
| `banners/{id}`                   | Admin                                      | User                          |
| `customers/{uid}`                | User (self), Admin                         | User, Admin                    |
| `customers/{uid}/cart_items/{}`  | User (self)                                | User                           |
| `orders/{id}`                    | User (create), Admin / Vendor / Delivery (status updates) | All four            |
| `delivery_boys/{id}`             | Admin (create), Delivery (live telemetry)  | User, Admin                    |
| `notifications/{uid}/items/{}`   | Cloud Functions / Admin                    | User                           |
| `admin_notifications/{id}`         | Cloud Functions (ops triggers)           | Admin Panel                    |
| `activity_logs/{id}`             | Cloud Functions                            | Admin Panel                    |
| `stock_alerts/{id}`              | Cloud Functions                            | Admin, Vendor (via push)       |
| `abandoned_carts/{id}`           | Cloud Functions (cart reminder job)      | Admin (read)                   |
| `delivery_tracking/{orderId}/events/{}` | Cloud Functions + Delivery App   | Admin, User                    |
| `daily_summaries/{id}`           | Cloud Functions (scheduled)                | Admin                          |
| `settings/ops_settings`          | Admin                                      | Cloud Functions                |
| `app_config/maintenance`         | Admin                                      | User, Vendor, Driver (realtime) |
| `maintenance_logs/{id}`          | Admin                                      | Admin (analytics)              |
| `coupons/{id}`                   | Admin                                      | User, Admin                    |
| `coupon_usages/{id}`             | Cloud Functions (`validateCoupon` / `redeemCoupon`) | Admin (analytics) |
| `combo_offers/{id}`              | Admin, Vendor (own vendorId)               | User, Admin, Vendor            |
| `delivery_zones/{id}`            | Admin                                      | User                           |
| `delivery_slots/{id}`            | Admin                                      | User                           |
| `ratings/{id}`                   | User (via Cloud Functions), Admin (moderation) | User, Admin, Vendor      |

---

## 2. Document schemas

### 2.1 `products/{id}`

```jsonc
{
  "name": "Tomatoes",
  "image": "https://…/tomatoes.jpg",   // cover = first gallery image
  "images": ["https://…/1.jpg", "https://…/2.jpg"],
  "product_images": ["https://…/1.jpg", "https://…/2.jpg"],  // alias of images (max 8)
  "videos": [],
  "description": "…",
  "category": "vegetables",
  "subcategory": "fresh",
  "unit": "kg",
  "unitPerItem": "1 kg",
  "stock": 24,
  "maxOrder": 5,
  "price": 39,
  "discountPrice": 29,           // preferred; falls back to "slashedPrice"
  "vendor_id": "vendor_xyz",
  "itemCount": 0,
  "most_sold": false,
  "product_index": 7,            // optional sort key — User App falls back to documentId when missing
  "special_cat": "Today's snacks deals",
  "addonIds": [],
  "selectedWeightInGrams": 1000,
  "rating": 4.6,                 // auto-updated from approved reviews
  "totalReviews": 132,
  "quality_score": 94,           // 0–100; auto from avg rating unless overridden
  "quality_score_override": null,// admin manual override (0–100)
  "featured_quality_badge": false,
  "premium_badge": false,
  "fresh_product_tag": false,
  "low_quality_alert_sent": false,
  "isTrending": true,
  "isFeatured": false,
  "is_active": true,
  "isAvailable": true,           // mirrored from is_active for User App
  "is_flash_sale": false,
  "is_todays_best": false,
  "is_most_selling": false,
  "most_sold": false,            // legacy alias of is_most_selling
  "is_recommended": false,
  "is_new_arrival": false,
  "limited_stock": false,
  "flash_sale_start": <Timestamp>,
  "flash_sale_end": <Timestamp>,
  "flash_sale_stock_limit": 0,
  "admin_featured_approved": true,
  "admin_settings_locked": false,
  "createdAt": <Timestamp>
}
```

* **Vendor App** writes: `stock`, `price`, `discountPrice`, `isAvailable`.
* **Admin Panel** writes: everything (CRUD).
* **User App** reads only.

### 2.2 `categories/{id}`

Existing schema kept — `id`, `category`, `image`, `isActive`, etc.

### 2.3 `banners/{id}`

```jsonc
{
  "id": "banner_1",
  "image": "https://…/banner.jpg",
  "video": "",
  "type": "image",                 // "image" | "video"
  "redirectType": "category",      // "category" | "product" | "url" | "none"
  "redirectId": "vegetables",
  "priority": 1,                   // ascending
  "isActive": true,
  "created_date": "2026-05-07",
  "createdAt": <Timestamp>
}
```

### 2.3.1 `combo_offers/{id}`

Product bundle offers (Milk + Bread, Rice + Oil, etc.) shown on the Offers hub.

```jsonc
{
  "id": "combo_abc",
  "title": "Breakfast combo",
  "subtitle": "Start your day right",
  "image": "https://…/combo.jpg",
  "productIds": ["p1", "p2", "p3"],
  "products": [
    { "productId": "p1", "name": "Milk", "image": "…", "quantity": 1, "unitPrice": 60 }
  ],
  "originalTotalPrice": 250,
  "comboPrice": 199,
  "discountPercent": 20,
  "vendorId": "vendor_xyz",        // empty = platform-wide
  "vendorName": "Fresh Mart",
  "stock": 50,
  "isActive": true,
  "isFlashSale": false,
  "isTrending": true,
  "startsAt": <Timestamp>,         // optional
  "endsAt": <Timestamp>,           // optional
  "priority": 10,
  "viewCount": 0,
  "orderCount": 0,
  "createdBy": "admin" | "vendor",
  "createdAt": <Timestamp>,
  "updatedAt": <Timestamp>
}
```

**Cart:** when a combo is added, each product line is stored in `cart/{uid}` with optional `comboId` and `comboGroupKey`; prices are scaled so line totals sum to `comboPrice`.

### 2.4 `customers/{uid}`

```jsonc
{
  "name": "Ahmed",
  "phone": "+91…",
  "email": "…",
  "fcmToken": "…",                 // written by RealtimeBootstrap on token refresh
  "fcmPlatform": "android" | "iOS" | "macOS" | …,
  "fcmUpdatedAt": <Timestamp>,
  "referred_by": "<otherUid>"
}
```

### 2.5 `orders/{id}` — the cross-app status hub

```jsonc
{
  "uuid": "<customer uid>",
  "customer_name": "…",
  "phone": "+91…",
  "address": "…",
  "products": [
    { "name": "…", "image": "…", "price": 29, "slashedPrice": 0,
      "itemCount": 2, "vendor_id": "…", "category": "…", "unit": "kg",
      "description": "…" }
  ],
  "delivery_charge": 25,
  "delivery_type": "express" | "standard",
  "isPaid": true,
  "order_status": "pending" | "accepted" | "packing" | "rider_assigned"
                | "out_for_delivery" | "delivered" | "cancelled",
  "isDelivered": false,
  "isCancelled": false,
  "deliveryBoyId": "<delivery_boys/{id}>",
  "is_rated": false,
  "star": 0,

  // Timeline timestamps (ISO strings)
  "created_date": "2026-05-08T14:03:00",
  "confrimTime": "",
  "driverShop":  "",
  "pickedTime":  "",
  "onTheWayTime":"",
  "deliveredTime":"",

  // Live position when out for delivery (mirrored from delivery_boys/{id})
  "lat": 12.97,
  "lng": 77.59,
  "current_location": "MG Road"
}
```

| Field                | Writer                                   |
| -------------------- | ---------------------------------------- |
| Initial create       | User App at checkout                     |
| `order_status`, `confrimTime`, `deliveryBoyId` | Admin Panel       |
| `driverShop`, `pickedTime` (vendor packed) | Vendor App                |
| `onTheWayTime`, `deliveredTime`, `lat`/`lng`/`current_location` | Delivery App |
| `isCancelled`        | User App (self) or Admin                 |

User App reads via `orderStreamProvider(orderId)` and `ordersStreamProvider`.

### 2.6 `delivery_boys/{id}` — rider profile + live telemetry

Partner auth/security fields (written by Cloud Functions `partner*` / `adminPartnerAccountAction`):

| Field | Type | Notes |
| ----- | ---- | ----- |
| `reset_otp` | string | HMAC-SHA256 hash of OTP (never plain text) |
| `otp_expiry` | Timestamp | OTP valid 5 minutes |
| `otp_attempts` | number | Wrong OTP count (max 3) |
| `last_otp_sent_at` | Timestamp | Resend cooldown 30s |
| `password_hash` | string | bcrypt hash (replaces plain `password`) |
| `failed_attempts` | number | Failed login count |
| `locked_until` | Timestamp | 30 min lock after 5 failures |
| `password_changed_at` | Timestamp | Last password change |
| `last_login` | map | `{ at, platform, deviceId, appVersion }` |
| `force_password_change` | boolean | Admin / reset flow |
| `session_version` | number | Increment to force logout all devices |

Same fields apply to `vendors/{id}` for the Vendor App login and forgot-password flow.

```jsonc
{
  "id": "rider_001",
  "name": "Asha",
  "phone": "+91…",
  "image": "https://…",

  // Realtime fields written by the Delivery App every few seconds:
  "lat": 12.97,
  "lng": 77.59,
  "heading": 92.3,                  // degrees, 0=N, 90=E
  "speed": 24.5,                    // km/h
  "isOnline": true,
  "online_status": true,
  "pause_deliveries": false,
  "updatedAt": <Timestamp>,

  // Earnings & wallet (Delivery App)
  "wallet_balance": 0,
  "total_earnings": 0,
  "pending_payout": 0,
  "driver_rating": 4.8,
  "total_deliveries": 0,
  "completed_orders": 0,
  "rejected_orders": 0,
  "incentives_total": 0,
  "acceptance_rate": 100,
  "on_time_percent": 92,

  // Profile extensions
  "vehicle_type": "Bike",
  "vehicle_number": "KA-01-AB-1234",
  "bank_account_name": "",
  "bank_account_number": "",
  "bank_ifsc": "",
  "upi_id": "",
  "documents": {
    "license": { "url": "", "status": "pending" }
  }
}
```

Subcollection `delivery_boys/{id}/wallet_transactions/{txId}` — earnings, withdrawals, penalties.

User App reads via `deliveryTrackingProvider(deliveryBoyId)`.
Throttle writes from the Delivery App to ~ once per 3–5 s to keep
Firestore costs sane; debounce when speed < 1 km/h.

### 2.7 `coupons/{id}` — advanced coupon rules

Managed from **Admin → Coupon Management**. Validated at checkout via Cloud Functions
`validateCouponCallable` / `redeemCouponCallable`.

```jsonc
{
  "code": "FIRST50",
  "coupon_type": "first_order | special_offer | festival_offer | free_delivery | percentage_discount | flat_discount | vendor_specific | product_specific",
  "discount": 50,
  "flat_amount": 0,
  "minimum_order_amount": 299,
  "maximum_discount_amount": 150,
  "minOrderValue": 299,
  "start_date": <Timestamp>,
  "expiry_date": <Timestamp>,
  "usage_limit": 1000,
  "used_count": 42,
  "per_user_limit": 1,
  "applicable_vendor_ids": ["vendor_xyz"],
  "applicable_product_ids": ["prod_a"],
  "applicable_category_ids": ["vegetables"],
  "free_delivery": false,
  "first_order_only": true,
  "one_per_device": true,
  "is_active": true,
  "description": "50% off your first order",
  "analytics_total_usage": 42,
  "analytics_failed_attempts": 8,
  "analytics_revenue": 12500,
  "analytics_first_order_users": 38,
  "createdAt": <Timestamp>
}
```

**First-order rules:** no prior non-cancelled `orders` for `uuid` or normalized `phone`;
optional one redemption per `deviceId` when `one_per_device` is true.

### 2.7b `coupon_usages/{id}` — redemption & failed attempts

```jsonc
{
  "couponId": "…",
  "couponCode": "FIRST50",
  "userId": "<Firebase Auth uid>",
  "phone": "9876543210",
  "deviceId": "qg_…",
  "success": true,
  "errorCode": "",
  "subtotal": 450,
  "discountApplied": 150,
  "orderId": "order_abc",
  "firstOrderCoupon": true,
  "createdAt": <Timestamp>
}
```

### 2.8 `notifications/{uid}/items/{notifId}` — in-app feed

```jsonc
{
  "title": "Order accepted",
  "body":  "Asha is on the way with your order.",
  "type":  "order" | "offer" | "delivery" | "system",
  "targetId": "<orderId | productId | offerId>",
  "deepLink": "/orders/abc123",
  "imageUrl": "",
  "read": false,
  "createdAt": <Timestamp>
}
```

* Cloud Functions write here when fanning out FCM, so the in-app feed
  works regardless of OS-level notification settings.
* Use the `read`/`createdAt` indexes (auto) to drive bell badges and
  the unread state.

User App reads via `notificationsStreamProvider` and
`unreadNotificationsCountProvider`.

### 2.8 `admin_notifications/{id}` — admin ops inbox

```jsonc
{
  "title": "New order",
  "message": "#a1b2c3 · Ahmed · ₹420 · COD",
  "type": "new_order",
  "category": "orders",
  "read": false,
  "soundAlert": true,
  "targetAdminId": "",
  "metadata": {
    "orderId": "…",
    "customerName": "…",
    "amount": 420,
    "paymentType": "COD",
    "vendorName": "Fresh Mart"
  },
  "createdAt": <Timestamp>
}
```

Written by Cloud Functions (`functions/src/operations/*`). Admin Panel
subscribes with `orderBy('createdAt', descending: true)` for the bell +
notification center.

### 2.9 `settings/ops_settings` — automation knobs

```jsonc
{
  "lowStockThreshold": 10,
  "autoDisableOutOfStock": true,
  "abandonedCartDelayHours": 24,
  "abandonedCartEnabled": true,
  "autoAssignDriver": true,
  "adminSoundEnabled": true
}
```

### 2.10 FCM topics (operations)

| Topic | Subscribers |
| ----- | ----------- |
| `admin_ops` | Admin mobile builds (optional) |
| `vendor_{vendorId}` | Vendor app after login |
| `delivery_{riderId}` | Delivery app after login |
| `all_users` | Customer app (marketing) |

---

## 3. Realtime fan-out matrix

| Change                                | Surfaces in User App via            |
| ------------------------------------- | ----------------------------------- |
| Admin adds/edits a product            | `productsByCategoryStreamProvider`, `inventoryStreamProvider`, all home rails |
| Vendor updates stock / price          | `productStreamProvider(id)` on detail screen, `inventoryStreamProvider` for cart |
| Admin changes banner                  | `bannersStreamProvider` (existing)  |
| Admin / Vendor flips `isAvailable`    | `productStreamProvider`, cart line strikethroughs |
| Admin assigns rider (`deliveryBoyId`) | `orderStreamProvider(id)` then `deliveryTrackingProvider` |
| Delivery app pushes lat/lng           | `deliveryTrackingProvider`          |
| Delivery app sets `out_for_delivery`  | `orderStreamProvider`               |
| Customer pays                         | `orderStreamProvider` (`isPaid`)    |
| Cloud Function writes to notifications| `notificationsStreamProvider`, `unreadNotificationsCountProvider` |

---

## 4. Consuming the streams (User App)

Single import gives every screen access to the realtime layer:

```dart
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';

final order = ref.watch(orderStreamProvider(orderId));
final rider = ref.watch(deliveryTrackingProvider(order.value?.deliveryBoyId ?? ''));
final inventory = ref.watch(inventoryStreamProvider(cartItemIds));
final unread = ref.watch(unreadNotificationsCountProvider);
```

Every provider is `autoDispose` — closing a screen tears down the
listener.

---

## 5. Offline persistence

`RealtimeBootstrap.configureFirestore()` runs in `main()` and sets:

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

Effect on the User App:

* Reads return cached data instantly when offline.
* Writes are queued and replayed when connectivity returns.
* Snapshot listeners fire from cache first, then network — UI never
  blanks during reconnects.

The existing offline banner in `home_screen.dart` (powered by
`connectivity_plus`) handles the visual indicator.

---

## 6. FCM bridge

`RealtimeBootstrap` listens for:

* `FirebaseMessaging.onMessage` (foreground) → in-app `SnackBar`.
* `FirebaseMessaging.onMessageOpenedApp` → reads `data.deepLink` for
  routing.
* `FirebaseMessaging.instance.onTokenRefresh` → persists token under
  `customers/{uid}.fcmToken`.
* On sign-in, the current token is fetched and persisted once.

Cloud Functions targeting an order should send:

```jsonc
{
  "notification": { "title": "…", "body": "…" },
  "data": {
    "deepLink": "/orders/<orderId>",
    "kind": "order"
  },
  "token": "<customer fcmToken>"
}
```

…**and** mirror the payload into `notifications/{uid}/items/{}` so the
in-app feed stays canonical.

---

## 7. Vendor / Admin / Delivery app obligations (for reference)

To make the realtime backbone work end-to-end, the other three apps
must:

* **Admin Panel**
  * Creates `products`, `categories`, `banners`, `coupons`,
    `delivery_zones`, `delivery_slots`, `delivery_boys`.
  * Updates `orders/{id}.order_status`, `confrimTime`, `deliveryBoyId`.
  * Has its own realtime dashboard reading `orders` (filter by date) and
    `delivery_boys` (online riders).

* **Vendor App**
  * Updates `products/{id}.stock`, `price`, `discountPrice`,
    `isAvailable`.
  * Updates assigned `orders/{id}.driverShop` (acknowledged) and
    `pickedTime` (handed off to rider).

* **Delivery App**
  * Streams my assigned orders: `where('deliveryBoyId', isEqualTo: me)`.
  * Updates the rider's own `delivery_boys/{me}` doc with `lat`,
    `lng`, `heading`, `speed`, `isOnline`, `updatedAt` every 3–5 s while
    on a delivery.
  * Updates `orders/{id}.onTheWayTime` and `deliveredTime`, mirrors
    `lat`/`lng`/`current_location` onto the order so the User App's
    map stays in sync without subscribing to the rider doc.

### 2.x `ratings/{id}` (product reviews)

Written by Cloud Functions (`submitProductReview`, etc.) after verified-purchase checks.
User cannot write directly from the client.

```jsonc
{
  "product_id": "prod_abc",
  "product_name": "Tomatoes",
  "vendor_id": "vendor_xyz",
  "order_id": "order_123",
  "user_id": "uid",
  "user_name": "Ahmed",
  "rating": 4.6,                    // overall (avg of category_ratings)
  "category_ratings": {
    "product_quality": 5,
    "freshness": 4,
    "packaging": 5,
    "delivery_experience": 4,
    "value_for_money": 5
  },
  "review_text": "Fresh and well packed.",
  "review_images": ["https://…/1.jpg"],
  "review_video": "",
  "verified_purchase": true,
  "admin_approved": false,
  "status": "pending",              // pending | approved | rejected | hidden
  "hidden": false,
  "is_featured": false,
  "helpful_count": 0,
  "reported_count": 0,
  "vendor_reply": { "text": "Thank you!", "repliedAt": <Timestamp> },
  "createdAt": <Timestamp>,
  "updatedAt": <Timestamp>
}
```

**Callables:** `canReviewProduct`, `submitProductReview`, `updateProductReview` (24h window),
`deleteProductReview`, `moderateProductReview` (admin), `vendorReplyProductReview`,
`markReviewHelpful`, `reportProductReview`.

**Indexes (recommended):** `vendor_id` + `createdAt`; `product_id` + `status`.

---

## 8. Performance tips already implemented (User App)

* Each home rail uses a dedicated `StreamProvider.autoDispose`, so
  Riverpod tears down listeners as the user scrolls away.
* The explore grid paginates with `startAfterDocument`, so the initial
  page is small (`limit: 18`) and the later pages stream in.
* `whereIn` for inventory is sharded into chunks of 30 (Firestore
  limit) and merged with `Rx.combineLatestList`.
* Per-doc parsing is wrapped in try/catch — one bad document never
  empties a list.
* `cached_network_image` on every banner / product image.
* `FirebaseFirestore.Settings.cacheSizeBytes = unlimited` for offline
  performance.
