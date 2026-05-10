# Orders & Live Tracking — Infrastructure

This document describes the Firestore schema, indexes, security rules, and
Google Maps migration path for the realtime order tracking system shipped
in Step 4.

## Firestore schema

### `orders/{orderId}`

Superset of the legacy schema — every legacy field is still written by the
checkout flow so admin/delivery apps keep working.

```jsonc
{
  // legacy
  "uuid":               "<userId>",
  "products":           [ /* ProductItem[] */ ],
  "created_date":       "2026-05-08 21:00:00",
  "customer_name":      "...",
  "phone":              "...",
  "address":            "...",
  "isPaid":             true,
  "order_status":       "Waiting",
  "deliveryBoyId":      "...",
  "isDelivered":        false,
  "isCancelled":        false,
  "delivery_type":      "standard",
  "is_rated":           false,
  "star":               0,
  "delivery_charge":    35,
  "current_location":   "...",
  "lat":                17.31,
  "lng":                78.48,

  // modern
  "status":               "pending|accepted|packing|out_for_delivery|delivered|cancelled",
  "paymentMethod":        "cod|upi|card|wallet",
  "paymentStatus":        "pending|paid|failed",
  "paymentRef":           "<razorpay txn id>",
  "delivery_slot":        { "id": "...", "label": "...", "start": <ts>, "end": <ts>, "isExpress": true },
  "delivery_instructions":"Leave at door",
  "bill":                 { "subtotal": 0, "deliveryFee": 0, "surgeFee": 0, "tax": 0, "handlingCharge": 0, "platformFee": 0, "couponDiscount": 0, "total": 0 },
  "coupon":               { "id": "...", "code": "...", "discount": 10 },
  "address_snapshot":     { "id":"...","name":"...","mobile":"...","address":"...","area":"...","type":"HOME" },
  "createdAt":            <serverTimestamp>,
  "cancelReason":         "...",
  "cancelledBy":          "customer|admin|rider",
  "cancelledAt":          <serverTimestamp>
}
```

### `orders/{orderId}/support_messages/{messageId}`

```jsonc
{
  "author":    "customer|support",
  "text":      "Hi, where is my order?",
  "createdAt": <serverTimestamp>,
  "uid":       "<userId>"
}
```

### `delivery_boys/{id}` and `delivery_boys/{id}/live/current`

Static profile lives at the parent doc:

```jsonc
{ "name": "...", "phone": "...", "image": "..." }
```

Realtime location is preferred at the subdoc — keeps tile-level write rate
isolated from profile reads:

```jsonc
delivery_boys/{id}/live/current = {
  "lat":         17.31,
  "lng":         78.48,
  "heading":     90,
  "lastUpdated": <serverTimestamp>
}
```

Legacy fallback: if the `live/current` subdoc is absent, the user app reads
`lat`/`lng` directly off the parent doc.

## Recommended Firestore indexes

| Collection | Fields |
| --- | --- |
| `orders` | `uuid` ASC + `createdAt` DESC (composite) — required by `watchUserOrders` |
| `orders` | `uuid` ASC + `status` ASC (composite) — optional, useful for tab pre-filtering |
| `orders/{id}/support_messages` | `createdAt` ASC (single-field) — usually auto |

The user app sorts client-side on `createdAt` so the first index is enough
to ship; add the second only when daily order volume per user exceeds ~30.

## Security rules (drop-in)

```
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }

    match /orders/{orderId} {
      allow read:   if signedIn() && resource.data.uuid == request.auth.uid;
      allow create: if signedIn() && request.resource.data.uuid == request.auth.uid;
      // Customer can only update non-fulfillment fields:
      allow update: if signedIn()
        && resource.data.uuid == request.auth.uid
        && request.resource.data.uuid == request.auth.uid
        && request.resource.data.diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'isCancelled','status','cancelReason','cancelledBy','cancelledAt',
                'is_rated','star'
              ]);
      allow delete: if false;

      match /support_messages/{messageId} {
        allow read:  if signedIn() && get(/databases/$(database)/documents/orders/$(orderId)).data.uuid == request.auth.uid;
        allow create: if signedIn()
          && request.resource.data.uid == request.auth.uid
          && request.resource.data.author == 'customer';
        allow update, delete: if false;
      }
    }

    match /delivery_boys/{id} {
      allow read: if signedIn();        // public-read for tracking
      allow write: if false;            // only the rider/admin app writes
      match /live/current {
        allow read: if signedIn();
        allow write: if false;
      }
    }
  }
}
```

Pair these rules with App Check (already enabled in `main.dart`) so only
your signed Android/iOS builds can hit Firestore.

## Battery & performance

- All Riverpod streams under `lib/view/orders/presentation/providers` are
  `autoDispose` — leaving the tracking screen detaches the rider-location
  listener within ~30s.
- The map widget uses `flutter_map` with `pinchZoom + drag + doubleTap`
  only; we do **not** enable rotation/animations that force GPU redraws.
- `riderLocationStreamProvider` is a `StreamProvider.family.autoDispose`
  keyed on `deliveryBoyId`, so tracking two orders side-by-side reuses
  one listener per rider.
- ETA is computed in `etaProvider`, a `Provider.autoDispose.family`. It
  recomputes only when the upstream order or rider stream emits — there is
  no timer / polling.

## Google Maps swap

The map is intentionally isolated in
`lib/view/orders/presentation/widgets/live_tracking_map.dart`. To swap
from `flutter_map` to `google_maps_flutter`:

1. **pubspec.yaml** — add `google_maps_flutter: ^2.6.0`.
2. **AndroidManifest.xml** — add inside `<application>`:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_ANDROID_KEY"/>
   ```
3. **iOS** — in `ios/Runner/AppDelegate.swift`:
   ```swift
   GMSServices.provideAPIKey("YOUR_IOS_KEY")
   ```
4. Replace the body of `LiveTrackingMap.build` with:
   ```dart
   GoogleMap(
     initialCameraPosition: CameraPosition(
       target: LatLng(center.latitude, center.longitude),
       zoom: 14,
     ),
     markers: {
       Marker(markerId: const MarkerId('drop'), position: ...),
       if (hasRider) Marker(markerId: const MarkerId('rider'), position: ...),
     },
     polylines: {
       if (hasRider) Polyline(polylineId: const PolylineId('route'),
         points: [rider!.position!, dropLocation]),
     },
   )
   ```
5. **No other file needs to change** — the same `LiveTrackingMap` props
   (`dropLocation`, `rider`, `height`) drive both implementations.

## Public surface (for other features)

| Provider | What it gives you |
| --- | --- |
| `userOrdersStreamProvider` | `AsyncValue<List<LiveOrder>>` for current user |
| `orderByIdStreamProvider(orderId)` | live single-order stream |
| `riderLocationStreamProvider(deliveryBoyId)` | live rider position |
| `etaProvider(orderId)` | derived `Duration` ETA |
| `supportMessagesStreamProvider(orderId)` | live chat thread |
| `reorderControllerProvider` | `.reorder(order)` puts items back into cart |
| `invoiceServiceProvider` | `.generateAndShare(order)` PDF + share sheet |
