# Theme system

Centralized Material 3 light / dark / system theming for Quick Grocery.

## Architecture

| File | Role |
|------|------|
| `theme_mode_option.dart` | `light` / `dark` / `system` enum + persistence keys |
| `theme_preference_service.dart` | SharedPreferences load/save |
| `theme_controller.dart` / `theme_provider.dart` | Riverpod `Notifier` (`themeModeProvider`) |
| `theme_extensions.dart` | `AppPalette` ThemeExtension (semantic grocery colors) |
| `app_colors.dart` | Brand + palette accessors |
| `theme_constants.dart` | 300ms animation + storage key constants |
| `app_theme.dart` | `AppTheme.light()` / `AppTheme.dark()` Material 3 theme data |
| `theme_system_ui.dart` | Status bar + navigation bar icons/colors |
| `themed_image_frame.dart` | Subtle border around light product art in dark mode |

Brand **primary stays amber** (`AppColor.primary`). Bright green and orange live on `AppPalette` as accents (`accentGreen`, `secondaryOrange`).

## How theme is applied

`MyApp` watches `themeModeProvider` and passes:

```dart
theme: AppTheme.light(),
darkTheme: AppTheme.dark(),
themeMode: themeOption.materialThemeMode,
themeAnimationDuration: AppTheme.animationDuration, // 300ms
```

Widgets rebuild through Flutter’s `Theme` InheritedWidget — not by rebuilding the whole tree from Riverpod.

## Reading colors in UI

Prefer contextual tokens:

```dart
final surface = AppSurface.of(context); // → AppPalette
final scheme = Theme.of(context).colorScheme;

Container(color: surface.card);
Text('Hi', style: TextStyle(color: surface.textPrimary));
Icon(Icons.star, color: surface.rating);
```

Never hardcode `Colors.white` / `Colors.black` / `Colors.grey` for backgrounds or body text.

Static `AppSurface.background` etc. remain as **light fallbacks** for rare non-context code — prefer `AppSurface.of(context)`.

## Appearance settings

Profile → **Appearance**: Light / Dark / System Default.

Preference key: `theme_mode` (`light` | `dark` | `system`).  
Default when missing: **system**.

## Adding a new theme color

1. Add fields on `AppPalette` (both `light` and `dark` consts).
2. Update `copyWith` and `lerp`.
3. Optionally wire into `AppTheme._build` (`ThemeData` / `ColorScheme`).
4. Use via `AppSurface.of(context).yourColor` or `context.appPalette.yourColor`.

Example — loyalty purple badge:

```dart
// in AppPalette
final Color loyaltyBadge;

// light: Color(0xFF7B61FF)
// dark:  Color(0xFFA78BFA)
```

## Package-specific notes

| Package | Guidance |
|---------|----------|
| CachedNetworkImage | Wrap in `ThemedNetworkImageFrame` when art has white backgrounds |
| Shimmer | Use `surface.shimmerBase` / `shimmerHighlight` (see `Skeleton`) |
| Google Maps | Use dark map style JSON when `context.isDarkTheme` |
| Razorpay / Camera / Image picker | System UI re-applied via `ThemeSystemUi.apply` in `MaterialApp.builder` |
| Lottie / SVG | Prefer theme-aware color filters for mono assets |
| QR | Foreground/background from `surface.textPrimary` / `surface.card` |

## Accessibility

- Contrast targets WCAG AA for text on surface/card.
- Typography uses Poppins with Material text scale (Dynamic Type).
- High-contrast: rely on `ColorScheme` + semantic palette; avoid low-alpha body text.
