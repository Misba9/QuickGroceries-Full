# Loading experience — migration report

Date: 2026-07-30  
Scope: Full `lib/core/loading/` + Home, Search, Cart, Checkout, Orders, Categories, Splash.

## New widgets / files created

| Path | Purpose |
|------|---------|
| `lib/core/loading/loading_categories.dart` | 20 grocery categories + emoji pool |
| `lib/core/loading/loading_messages.dart` | Friendly / search / cart / orders / checkout copy |
| `lib/core/loading/loading_random.dart` | Anti-repeat randomizer |
| `lib/core/loading/loading_controller.dart` | Riverpod `LoadingMoment` + constants |
| `lib/core/loading/loading_assets.dart` | Fonts / Lottie / logo preload |
| `lib/core/loading/navigation_loading.dart` | Page-kind → skeleton map |
| `lib/core/loading/widgets/shimmer_widgets.dart` | Theme shimmer primitives |
| `lib/core/loading/widgets/animated_category_loader.dart` | Bounce/float/rotate category loader |
| `lib/core/loading/widgets/skeleton_product_card.dart` | Product card / rail / grid |
| `lib/core/loading/widgets/skeleton_banner.dart` | Banner, category rail, vendor |
| `lib/core/loading/widgets/skeleton_cart.dart` | Cart + checkout skeletons |
| `lib/core/loading/widgets/skeleton_order.dart` | Orders list + timeline |
| `lib/core/loading/widgets/skeleton_search.dart` | Search fill / full |
| `lib/core/loading/widgets/skeleton_home.dart` | Composite home skeleton |
| `lib/core/loading/widgets/loading_overlay.dart` | Overlay + MinLoadingGate |
| `lib/core/loading/widgets/offline_loading_view.dart` | Offline + retry |
| `lib/core/loading/loading.dart` | Barrel |
| `lib/core/loading/README.md` | Developer docs |

## Files modified

- `app_animated_splash.dart` — gradient, rotating grocery emoji/category, asset warm-up
- `home_bootstrap_shimmer.dart` — uses `SkeletonHome` + themed tab bones
- `bootstrap_loading_messages.dart` — expanded grocery-aware copy
- `home_shimmer.dart` — themed `ShimmerBox` (dark mode)
- `cart_shimmer.dart` — delegates to `SkeletonCart`
- `search_screen.dart` — `SkeletonSearchFill` instead of spinner
- `orders_screen.dart` — `SkeletonOrder` instead of spinner
- `checkout_screen.dart` — `SkeletonCheckout` while cart hydrates
- `category_screen.dart` — `SkeletonProductGrid`
- `product_detail_shimmer.dart` — product page skeleton
- `home_screen.dart` — premium `OfflineLoadingView`
- `skeleton.dart` — card fill uses theme surface

## Performance optimizations

1. Local `AnimationController`s disposed in loaders; timers cancelled on dispose.
2. Shimmer / bounce / float skip when `MediaQuery.disableAnimationsOf` (Reduce Motion).
3. `LoadingAssets.warmUp()` runs async from splash — doesn’t block first frame.
4. Skeletons match real card sizes to avoid layout jump.
5. `MinLoadingGate` (400ms) available to prevent flash without delaying long responses.
6. Anti-repeat randomizer avoids same category/message twice in a row.
7. Riverpod/providers unchanged — only view-layer loading UI swapped.

## Remaining improvements

1. Wrap more `CircularProgressIndicator` call sites (profile, referrals, webview, support chat) with `Skeleton*` / `LoadingOverlay`.
2. Adopt `MinLoadingGate` on fast AsyncValue streams that still micro-flash.
3. Optional grocery **Lottie** packing scene if design delivers a dedicated asset (burger.json unused today).
4. Native Android/iOS splash still static until Flutter paints.
5. Search `ChangeNotifier` could eventually expose `isLoading` AsyncValue for cleaner gating.
6. Google Maps loaders still use generic indicators.

## Screens covered

| Screen | Loading UI |
|--------|------------|
| Cold start splash | Logo + emoji + category message + progress |
| Bootstrap → home | `SkeletonHome` |
| Home sections | Themed `HomeShimmer` / `SkeletonRail` |
| Home offline | `OfflineLoadingView` |
| Search | `SkeletonSearchFill` |
| Cart | `SkeletonCart` |
| Checkout hydrate | `SkeletonCheckout` |
| Orders tabs | `SkeletonOrder` |
| Category products | `SkeletonProductGrid` |
| Product detail | Product skeleton via `NavigationLoading` |
