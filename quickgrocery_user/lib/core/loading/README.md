# Premium Loading System

Blinkit / Zepto / Instamart-inspired loading experience for Quick Grocery.

## Package

`package:quickgrocery/core/loading/loading.dart`

## Building blocks

| Widget | Use when |
|--------|----------|
| `AnimatedCategoryLoader` | Branded emoji + rotating grocery category message |
| `CategoryLoaderBanner` | Compact strip above a skeleton page |
| `SkeletonHome` | Full home first-frame |
| `SkeletonProductCard` / `Rail` / `Grid` | Product surfaces |
| `SkeletonBanner` / `SkeletonCategory` / `SkeletonVendor` | Home sections |
| `SkeletonCart` / `SkeletonCheckout` | Cart & checkout |
| `SkeletonOrder` / `SkeletonOrderTimeline` | Orders |
| `SkeletonSearch` / `SkeletonSearchFill` | Search |
| `LoadingOverlay` | Soft modal wait without replacing route |
| `MinLoadingGate` | Enforce 400ms min display, hide instantly after if longer |
| `OfflineLoadingView` | No infinite spinner when offline |
| `NavigationLoading.forPage(...)` | Pick a page skeleton by `LoadingPageKind` |

## Random category + message

```dart
final moment = LoadingMoment.fresh(); // anti-repeat
// or rotate via AnimatedCategoryLoader (built-in Timer)
```

Categories live in `LoadingCategories`. Messages in `LoadingMessages`.

## Theme + a11y

- Shimmer colors from `AppPalette` (light/dark).
- `MediaQuery.disableAnimationsOf` freezes bounce/float and shimmer when Reduce Motion is on.
- `Semantics(liveRegion: true)` announces message changes.

## Wiring examples

```dart
async.when(
  loading: () => const SkeletonOrder(),
  error: ...,
  data: ...,
);

// Cart
if (cart.isHydrating && cart.isEmpty) return const SkeletonCart();

// Min flash guard
MinLoadingGate(
  loading: async.isLoading,
  loadingBuilder: (_) => const SkeletonProductGrid(),
  child: content,
);
```

## Assets

`LoadingAssets.warmUp()` preloads logo + Lottie bytes (`load.json`, `burger.json`). Called from splash.

Optional Lottie: place grocery packing animation under `assets/lottie/` and swap into `AnimatedCategoryLoader` later.
