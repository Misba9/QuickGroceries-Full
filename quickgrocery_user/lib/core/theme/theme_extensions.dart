import 'package:flutter/material.dart';

/// Semantic grocery-app colors that sit beside Material [ColorScheme].
///
/// Access via [Theme.of] → `extension<AppPalette>()` or [AppSurface.of].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.scaffold,
    required this.card,
    required this.subtle,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.iconActive,
    required this.iconInactive,
    required this.iconDisabled,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.discount,
    required this.offerBadge,
    required this.flashSale,
    required this.vendorBadge,
    required this.rating,
    required this.ratingEmpty,
    required this.orderPending,
    required this.orderConfirmed,
    required this.orderPacked,
    required this.orderOutForDelivery,
    required this.orderDelivered,
    required this.orderCancelled,
    required this.imageBorder,
    required this.shadow,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.accentGreen,
    required this.secondaryOrange,
  });

  final Color background;
  final Color scaffold;
  final Color card;
  final Color subtle;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color iconActive;
  final Color iconInactive;
  final Color iconDisabled;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color discount;
  final Color offerBadge;
  final Color flashSale;
  final Color vendorBadge;
  final Color rating;
  final Color ratingEmpty;
  final Color orderPending;
  final Color orderConfirmed;
  final Color orderPacked;
  final Color orderOutForDelivery;
  final Color orderDelivered;
  final Color orderCancelled;
  final Color imageBorder;
  final Color shadow;
  final Color shimmerBase;
  final Color shimmerHighlight;
  /// Bright grocery green accent (not primary — amber remains brand primary).
  final Color accentGreen;
  final Color secondaryOrange;

  /// Alias used across the app historically.
  Color get text => textPrimary;

  static const light = AppPalette(
    background: Color(0xFFF6F7FB),
    scaffold: Color(0xFFF6F7FB),
    card: Color(0xFFFFFFFF),
    subtle: Color(0xFFEFEFF3),
    border: Color(0xFFE6E6EC),
    divider: Color(0xFFE6E6EC),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF555560),
    textMuted: Color(0xFF6B6B73),
    iconActive: Color(0xFF111114),
    iconInactive: Color(0xFF8A8A96),
    iconDisabled: Color(0xFFB8B8C0),
    success: Color(0xFF11A04C),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF5A524),
    onWarning: Color(0xFF1A1200),
    danger: Color(0xFFD92D2D),
    onDanger: Color(0xFFFFFFFF),
    discount: Color(0xFFE53935),
    offerBadge: Color(0xFFFF6B00),
    flashSale: Color(0xFFFF3D5A),
    vendorBadge: Color(0xFF1A73E8),
    rating: Color(0xFFFFB300),
    ratingEmpty: Color(0xFFD0D0D8),
    orderPending: Color(0xFFF5A524),
    orderConfirmed: Color(0xFF1A73E8),
    orderPacked: Color(0xFF7B61FF),
    orderOutForDelivery: Color(0xFFFF6B00),
    orderDelivered: Color(0xFF11A04C),
    orderCancelled: Color(0xFFD92D2D),
    imageBorder: Color(0xFFE6E6EC),
    shadow: Color(0x0A000000),
    shimmerBase: Color(0xFFE8E8EE),
    shimmerHighlight: Color(0xFFF5F5F8),
    accentGreen: Color(0xFF16A34A),
    secondaryOrange: Color(0xFFFF6B00),
  );

  /// True dark (#121212 / #1E1E1E / #242424) — no washed-out greys.
  static const dark = AppPalette(
    background: Color(0xFF121212),
    scaffold: Color(0xFF121212),
    card: Color(0xFF242424),
    subtle: Color(0xFF2A2A2A),
    border: Color(0xFF333333),
    divider: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB3B3B3),
    textMuted: Color(0xFF8C8C8C),
    iconActive: Color(0xFFFFFFFF),
    iconInactive: Color(0xB3FFFFFF), // white70
    iconDisabled: Color(0x61FFFFFF), // white38
    success: Color(0xFF22C55E),
    onSuccess: Color(0xFF001A0A),
    warning: Color(0xFFFFB020),
    onWarning: Color(0xFF1A1200),
    danger: Color(0xFFFF5252),
    onDanger: Color(0xFF1A0000),
    discount: Color(0xFFFF6B6B),
    offerBadge: Color(0xFFFF8A3D),
    flashSale: Color(0xFFFF5A73),
    vendorBadge: Color(0xFF5B9FFF),
    rating: Color(0xFFFFC107),
    ratingEmpty: Color(0xFF4A4A4A),
    orderPending: Color(0xFFFFB020),
    orderConfirmed: Color(0xFF5B9FFF),
    orderPacked: Color(0xFFA78BFA),
    orderOutForDelivery: Color(0xFFFF8A3D),
    orderDelivered: Color(0xFF22C55E),
    orderCancelled: Color(0xFFFF5252),
    imageBorder: Color(0xFF3A3A3A),
    shadow: Color(0x66000000),
    shimmerBase: Color(0xFF2A2A2A),
    shimmerHighlight: Color(0xFF3A3A3A),
    accentGreen: Color(0xFF4ADE80),
    secondaryOrange: Color(0xFFFF8A3D),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? scaffold,
    Color? card,
    Color? subtle,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? iconActive,
    Color? iconInactive,
    Color? iconDisabled,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? danger,
    Color? onDanger,
    Color? discount,
    Color? offerBadge,
    Color? flashSale,
    Color? vendorBadge,
    Color? rating,
    Color? ratingEmpty,
    Color? orderPending,
    Color? orderConfirmed,
    Color? orderPacked,
    Color? orderOutForDelivery,
    Color? orderDelivered,
    Color? orderCancelled,
    Color? imageBorder,
    Color? shadow,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? accentGreen,
    Color? secondaryOrange,
  }) {
    return AppPalette(
      background: background ?? this.background,
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      subtle: subtle ?? this.subtle,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      iconActive: iconActive ?? this.iconActive,
      iconInactive: iconInactive ?? this.iconInactive,
      iconDisabled: iconDisabled ?? this.iconDisabled,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      discount: discount ?? this.discount,
      offerBadge: offerBadge ?? this.offerBadge,
      flashSale: flashSale ?? this.flashSale,
      vendorBadge: vendorBadge ?? this.vendorBadge,
      rating: rating ?? this.rating,
      ratingEmpty: ratingEmpty ?? this.ratingEmpty,
      orderPending: orderPending ?? this.orderPending,
      orderConfirmed: orderConfirmed ?? this.orderConfirmed,
      orderPacked: orderPacked ?? this.orderPacked,
      orderOutForDelivery: orderOutForDelivery ?? this.orderOutForDelivery,
      orderDelivered: orderDelivered ?? this.orderDelivered,
      orderCancelled: orderCancelled ?? this.orderCancelled,
      imageBorder: imageBorder ?? this.imageBorder,
      shadow: shadow ?? this.shadow,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      accentGreen: accentGreen ?? this.accentGreen,
      secondaryOrange: secondaryOrange ?? this.secondaryOrange,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      scaffold: mix(scaffold, other.scaffold),
      card: mix(card, other.card),
      subtle: mix(subtle, other.subtle),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      iconActive: mix(iconActive, other.iconActive),
      iconInactive: mix(iconInactive, other.iconInactive),
      iconDisabled: mix(iconDisabled, other.iconDisabled),
      success: mix(success, other.success),
      onSuccess: mix(onSuccess, other.onSuccess),
      warning: mix(warning, other.warning),
      onWarning: mix(onWarning, other.onWarning),
      danger: mix(danger, other.danger),
      onDanger: mix(onDanger, other.onDanger),
      discount: mix(discount, other.discount),
      offerBadge: mix(offerBadge, other.offerBadge),
      flashSale: mix(flashSale, other.flashSale),
      vendorBadge: mix(vendorBadge, other.vendorBadge),
      rating: mix(rating, other.rating),
      ratingEmpty: mix(ratingEmpty, other.ratingEmpty),
      orderPending: mix(orderPending, other.orderPending),
      orderConfirmed: mix(orderConfirmed, other.orderConfirmed),
      orderPacked: mix(orderPacked, other.orderPacked),
      orderOutForDelivery: mix(orderOutForDelivery, other.orderOutForDelivery),
      orderDelivered: mix(orderDelivered, other.orderDelivered),
      orderCancelled: mix(orderCancelled, other.orderCancelled),
      imageBorder: mix(imageBorder, other.imageBorder),
      shadow: mix(shadow, other.shadow),
      shimmerBase: mix(shimmerBase, other.shimmerBase),
      shimmerHighlight: mix(shimmerHighlight, other.shimmerHighlight),
      accentGreen: mix(accentGreen, other.accentGreen),
      secondaryOrange: mix(secondaryOrange, other.secondaryOrange),
    );
  }
}

/// Convenience: `context.appPalette`.
extension AppPaletteContext on BuildContext {
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
