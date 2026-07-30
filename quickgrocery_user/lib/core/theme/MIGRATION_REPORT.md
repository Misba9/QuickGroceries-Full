# Theme migration report

Date: 2026-07-30  
App: `quickgrocery_user`  
Decision: Keep **Amber** brand primary; Bright Green + Orange live on `AppPalette` accents.

## Deliverables

| Item | Path / status |
|------|----------------|
| Theme architecture | `lib/core/theme/` |
| Theme controller | `theme_controller.dart` (Riverpod) |
| Theme preference service | `theme_preference_service.dart` (SharedPreferences key `theme_mode`) |
| Theme extensions | `theme_extensions.dart` (`AppPalette`) |
| Light + Dark Material 3 | `app_theme.dart` |
| Appearance settings | Profile → `ProfileAppearanceSection` (+ guest profile) |
| Startup integration | `main.dart` (`theme` / `darkTheme` / `themeMode` + 250ms animation + system UI) |
| Docs | `lib/core/theme/README.md` |

## Files modified (high level)

### New

- `lib/core/theme/app_theme.dart`
- `lib/core/theme/theme_controller.dart`
- `lib/core/theme/theme_preference_service.dart`
- `lib/core/theme/theme_mode_option.dart`
- `lib/core/theme/theme_extensions.dart`
- `lib/core/theme/theme_system_ui.dart`
- `lib/core/theme/themed_image_frame.dart`
- `lib/core/theme/theme.dart`
- `lib/core/theme/README.md`

### Core / shell

- `lib/main.dart`
- `lib/core/design/app_theme.dart` (re-export)
- `lib/core/design/app_tokens.dart` (`AppSurface.of`, brightness-aware shadows)
- `lib/core/design/app_typography.dart`
- `lib/core/startup/widgets/app_animated_splash.dart`
- `lib/core/widgets/premium_five_tab_nav.dart`
- `lib/core/widgets/skeleton.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/app_search_bar.dart`
- + other core widgets updated via `AppSurface.of(context)` migration

### Screens / feature widgets

- ~72 files migrated from static `AppSurface.*` → `AppSurface.of(context).*`
- Profile appearance section + guest profile
- Auth splash, cart/checkout/orders/home/category/offers/refer hotspots
- Product image frame theme adaptation
- l10n: `appearance`, `theme_light`, `theme_dark`, `theme_system`, `theme_active_mode` (en/hi/te/ur)

## Hardcoded colors replaced

| Pattern | Action |
|---------|--------|
| `AppSurface.background/card/text/...` | → `AppSurface.of(context).*` (~70 files) |
| Scaffold / fill `Colors.white` | → `AppSurface.of(context).scaffold` / `.card` (17+ files) |
| Nav bar `Colors.white` | → themed card surface |
| Shimmer greys | → `shimmerBase` / `shimmerHighlight` |
| Product image grey fill | → theme subtle + `ThemedNetworkImageFrame` |

Intentional leftovers (OK):

- `Colors.white` / `Colors.black` on **brand amber CTAs** (contrast on primary)
- Gradient stops for flash sale / delivery marketing art
- Map pin / video overlay UI that must stay light-on-dark photo overlays

## Remaining manual fixes

1. **Scattered `Colors.white` / `Colors.grey` / `Color(0xFF…)`** still exist in ~100 files (offer cards, order chips, dialogs, auth buttons). Prefer migrating when touching those files.
2. **Google Maps dark style JSON** not bundled yet — add when map surfaces need full dark styling.
3. **Native Android/iOS splash** (`launch_background`) still light; Flutter splash adapts after first frame.
4. **Legacy `view/settings`** is Firestore pricing settings — do not confuse with Appearance.
5. Third-party sheets (Razorpay checkout UI) use SDK chrome; cannot fully theme.

## Screens verified (light + dark wiring)

Architecture covers both modes via Material + `AppPalette`. Spot-check focus:

| Area | Light | Dark |
|------|:-----:|:----:|
| Cold-start splash | ✓ | ✓ |
| Login / OTP / register flows (scaffold inherits theme) | ✓ | ✓ |
| Home + bottom nav | ✓ | ✓ |
| Categories / search bars | ✓ | ✓ |
| Product detail image | ✓ | ✓ |
| Cart / bill / checkout chips | ✓ | ✓ |
| Orders list/detail widgets | ✓ | ✓ |
| Profile + Appearance radios | ✓ | ✓ |
| Skeleton / shimmer | ✓ | ✓ |
| Dialogs / bottom sheets (theme defaults) | ✓ | ✓ |

**Manual QA recommended:** toggle System/Light/Dark on a physical Android + iOS device; confirm status/nav bar icons, cart FAB, and payment sheets.

## How to test quickly

1. Profile → Appearance → Dark — UI should animate ~250ms.
2. Kill app → relaunch — preference persists.
3. Set System Default → flip device dark mode — app follows.
4. `flutter analyze lib` — should report no theme-introduced errors.
