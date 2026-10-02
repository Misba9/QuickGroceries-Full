# Theme migration report

Date: 2026-07-31  
App: `quickgrocery_user`  
Brand primary: **Amber** (`AppColor.primary`). Accents: green + orange on `AppPalette`.

## Architecture (complete)

| File | Role |
|------|------|
| `lib/core/theme/app_theme.dart` | Material 3 light / dark `ThemeData` |
| `lib/core/theme/app_colors.dart` | Brand + palette accessors |
| `lib/core/theme/theme_extensions.dart` | `AppPalette` ThemeExtension |
| `lib/core/theme/theme_controller.dart` | Riverpod theme controller |
| `lib/core/theme/theme_provider.dart` | Re-export alias for controller |
| `lib/core/theme/theme_preference_service.dart` | SharedPreferences persistence |
| `lib/core/theme/theme_mode_option.dart` | Light / Dark / System |
| `lib/core/theme/theme_constants.dart` | 300ms animation + storage keys |
| `lib/core/theme/theme_system_ui.dart` | Status / nav bar overlays |
| `lib/core/theme/themed_image_frame.dart` | Product image frame in dark |
| `lib/core/design/app_tokens.dart` | `AppSurface.of(context)` API |

**Modes:** Light · Dark · System (follows Android/iOS appearance)  
**Persistence:** `theme_mode` in SharedPreferences  
**Animation:** 300ms `AnimatedTheme` + MaterialApp `themeAnimationDuration`

## Files modified in this pass

### Theme system (new / updated)
- `lib/core/theme/app_colors.dart` *(new)*
- `lib/core/theme/theme_constants.dart` *(new)*
- `lib/core/theme/theme_provider.dart` *(new)*
- `lib/core/theme/app_theme.dart` (300ms)
- `lib/core/theme/theme.dart` (barrel exports)
- `lib/core/theme/theme_preference_service.dart`

### Core widgets
- `app_search_bar.dart`, `modern_bottom_nav.dart`, `premium_five_tab_nav.dart`
- `glass_card.dart`, `animated_add_button.dart`, `global_floating_cart_widget.dart`

### Home
- `home_delivery_header.dart` (header gradient + notifications sheet)
- `product_card.dart`, `home_screen.dart`, `home_status_views.dart`
- `flash_sale_section.dart`, `home_banner_*`, `fallback_banner_slider.dart`
- `cached_image.dart`, `category_tile.dart`, `home_categories_rail.dart`
- `recently_ordered_section.dart`, `addon_screen.dart`

### Categories / products
- `premium_product_card.dart`, `category_product_card.dart`
- `animated_category_card.dart`
- `cart_action_bar.dart` (product detail bottom bar)

### Orders
- `orders_screen.dart`, `order_card_modern.dart`, `order_timeline_widget.dart`
- `order_actions_bar.dart`, `rider_card.dart`, `order_tracking_*`
- `order_details_card.dart`
- Legacy tabs: `processing_tab.dart`, `delivery_tab.dart`, `cancelled_tab.dart`

### Cart / checkout
- `cart_header.dart`, `premium_cart_item_card.dart`, `premium_checkout_bar.dart`
- `checkout_coupon_section.dart`, `checkout_tip_section.dart`
- `premium_bill_card.dart`, `free_delivery_banner.dart`
- `checkout_screen.dart`, `checkout_bottom_bar.dart`
- `address_card.dart`, `payment_chip.dart`, `delivery_slot_chip.dart`
- Address screens: `address_screen.dart`, `add_address_screen.dart`

### Offers / combo / coupons
- `offers_screen.dart`, `offer_category_chips.dart`
- `combo_offer_card.dart`, `combo_detail_screen.dart`
- `coupon_screen.dart`

### Profile / notifications
- `guest_profile_view.dart`, `profile_sections.dart`, `profile_section_safe.dart`
- `notification_center_screen.dart`

### Misc
- `animated_app_heading.dart` (theme-aware shimmer)

## Remaining (manual / lower priority)

These still contain some `Colors.white` / grey — often **intentional** (amber CTA contrast, photo overlays, marketing gradients):

| Area | Notes |
|------|--------|
| `global_floating_cart_widget.dart` | White accents on amber FAB — brand intentional |
| `discount_badge.dart` / `quantity_stepper.dart` | White on primary/danger — OK |
| `free_delivery_banner.dart` | White text on green gradient — OK |
| `refer_screen.dart` / `refer_share_actions.dart` | Hero / share UI still partly light |
| `live_tracking_map.dart` | Map overlays — light-on-map OK |
| `offer_promo_video_card.dart` | Video chrome overlays |
| `post_delivery_tip_sheet.dart` | Tip sheet needs follow-up |
| `home_section_error_card.dart` / connection-lost screens | Grey text → migrate next touch |
| `product_view` review / image carousel | Overlay whites often intentional |
| Native splash (`launch_background`) | Still light until Flutter first frame |
| Razorpay / Maps SDK chrome | Cannot fully theme |
| Thermal PDF receipt | Print colors — leave as-is |

## How to verify

1. Profile → Appearance → **Dark** — ~300ms animated switch.
2. Kill app → relaunch — preference persists.
3. Set **System** → flip device appearance — app follows.
4. Spot-check: Home header, product cards, search bar, bottom nav, notifications sheet, Orders, Offers, Guest Profile, Cart, Checkout, Coupons.

## Acceptance checklist

| Criterion | Status |
|-----------|:------:|
| Material 3 light + dark + system | ✓ |
| Theme persistence | ✓ |
| Smooth 300ms transition | ✓ |
| Status / nav bar overlays | ✓ |
| Home / cards / search / nav | ✓ |
| Notifications sheet | ✓ |
| Orders (modern UI) | ✓ |
| Guest profile + appearance | ✓ |
| Offers / combo / coupons | ✓ |
| Cart / checkout bars | ✓ |
| Product detail action bar | ✓ |
| Zero remaining hardcoded surfaces | Partial — see remaining table |
