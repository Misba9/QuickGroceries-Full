import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/app_typography.dart';
import 'package:quickgrocery/core/theme/theme_system_ui.dart';

/// Material 3 light & dark themes for Quick Grocery.
///
/// Brand primary remains amber ([AppColor.primary]). Bright green and orange
/// live on [AppPalette] as accents — see `lib/core/theme/README.md`.
class AppTheme {
  AppTheme._();

  static const Duration animationDuration = Duration(milliseconds: 250);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        palette: AppPalette.light,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        palette: AppPalette.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = AppColor.primary;
    final onPrimary = isDark ? const Color(0xFF1A1400) : Colors.black;
    final secondary = palette.secondaryOrange;
    final onSecondary = isDark ? const Color(0xFF1A0A00) : Colors.white;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer:
          isDark ? const Color(0xFF5C4A00) : const Color(0xFFFFF3C4),
      onPrimaryContainer:
          isDark ? const Color(0xFFFFE082) : const Color(0xFF3D2E00),
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer:
          isDark ? const Color(0xFF5C2E00) : const Color(0xFFFFE0C2),
      onSecondaryContainer:
          isDark ? const Color(0xFFFFD0A8) : const Color(0xFF3D1A00),
      tertiary: palette.accentGreen,
      onTertiary: isDark ? const Color(0xFF002010) : Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
      onTertiaryContainer:
          isDark ? const Color(0xFFBBF7D0) : const Color(0xFF052E16),
      error: palette.danger,
      onError: palette.onDanger,
      errorContainer:
          isDark ? const Color(0xFF5C1010) : const Color(0xFFFFE5E5),
      onErrorContainer:
          isDark ? const Color(0xFFFFCDD2) : const Color(0xFF5C1010),
      surface: palette.card,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.subtle,
      surfaceContainerHigh: isDark ? const Color(0xFF1E1E1E) : palette.subtle,
      surfaceContainer: isDark ? const Color(0xFF1A1A1A) : palette.background,
      surfaceContainerLow: palette.background,
      surfaceContainerLowest: isDark ? const Color(0xFF0E0E0E) : Colors.white,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.divider,
      shadow: palette.shadow,
      scrim: Colors.black54,
      inverseSurface: isDark ? Colors.white : const Color(0xFF1E1E1E),
      onInverseSurface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      inversePrimary: isDark ? const Color(0xFFFFC107) : const Color(0xFF5C4A00),
      surfaceTint: primary,
    );

    final textTheme = AppTypography.textTheme(palette: palette);

    final radiusMd = AppRadii.all(AppRadii.md);
    final radiusLg = AppRadii.all(AppRadii.lg);
    final radiusPill = AppRadii.all(AppRadii.pill);

    final buttonText = GoogleFonts.poppins(
      fontWeight: FontWeight.w800,
      fontSize: 14,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.scaffold,
      canvasColor: palette.background,
      cardColor: palette.card,
      dividerColor: palette.divider,
      disabledColor: palette.iconDisabled,
      hintColor: palette.textMuted,
      shadowColor: palette.shadow,
      splashColor: primary.withValues(alpha: 0.12),
      highlightColor: primary.withValues(alpha: 0.08),
      hoverColor: primary.withValues(alpha: 0.06),
      focusColor: primary.withValues(alpha: 0.14),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: primary.withValues(alpha: 0.28),
        selectionHandleColor: primary,
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: IconThemeData(color: palette.iconActive, size: 22),
      primaryIconTheme: IconThemeData(color: onPrimary, size: 22),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: <ThemeExtension<dynamic>>[palette],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.card,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 16),
        iconTheme: IconThemeData(color: palette.iconActive),
        actionsIconTheme: IconThemeData(color: palette.iconActive),
        systemOverlayStyle: ThemeSystemUi.forBrightness(
          brightness,
          navigationBarColor: palette.card,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shadowColor: palette.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: palette.subtle,
          disabledForegroundColor: palette.iconDisabled,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: palette.subtle,
          disabledForegroundColor: palette.iconDisabled,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          elevation: 0,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          disabledForegroundColor: palette.iconDisabled,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: palette.border, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: radiusMd),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textPrimary,
          disabledForegroundColor: palette.iconDisabled,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        indicatorColor: primary.withValues(alpha: isDark ? 0.22 : 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? palette.textPrimary : palette.iconInactive,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.iconActive : palette.iconInactive,
            size: 24,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.card,
        selectedItemColor: palette.textPrimary,
        unselectedItemColor: palette.iconInactive,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.card,
        indicatorColor: primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: palette.iconActive),
        unselectedIconTheme: IconThemeData(color: palette.iconInactive),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: palette.textMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? palette.subtle : palette.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        prefixIconColor: palette.iconInactive,
        suffixIconColor: palette.iconInactive,
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: AppColor.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: palette.danger, width: 1.4),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: palette.border.withValues(alpha: 0.5)),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(
          isDark ? palette.subtle : palette.card,
        ),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: radiusPill),
        ),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
        textStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        ),
      ),
      searchViewTheme: SearchViewThemeData(
        backgroundColor: palette.background,
        dividerColor: palette.divider,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? palette.subtle : palette.card,
        disabledColor: palette.subtle,
        selectedColor: primary.withValues(alpha: isDark ? 0.28 : 0.18),
        secondarySelectedColor: secondary.withValues(alpha: 0.2),
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: radiusPill),
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.textPrimary),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: palette.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primary.withValues(alpha: isDark ? 0.28 : 0.18);
            }
            return palette.card;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.textPrimary;
            }
            return palette.textSecondary;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? palette.textMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return palette.subtle;
        }),
        trackOutlineColor: WidgetStatePropertyAll(palette.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(onPrimary),
        side: BorderSide(color: palette.border, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return palette.iconInactive;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: palette.subtle,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.16),
        valueIndicatorColor: palette.textPrimary,
        valueIndicatorTextStyle:
            textTheme.labelSmall?.copyWith(color: palette.card),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: palette.card,
          border: OutlineInputBorder(
            borderRadius: radiusMd,
            borderSide: BorderSide(color: palette.border),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.divider,
        thickness: 1,
        space: 24,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.iconActive,
        textColor: palette.textPrimary,
        subtitleTextStyle:
            textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: palette.card,
        collapsedBackgroundColor: palette.card,
        iconColor: palette.iconActive,
        collapsedIconColor: palette.iconInactive,
        textColor: palette.textPrimary,
        collapsedTextColor: palette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        collapsedShape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: palette.subtle,
        circularTrackColor: palette.subtle,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: palette.textPrimary,
        unselectedLabelColor: palette.textMuted,
        indicatorColor: primary,
        dividerColor: palette.divider,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.08)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        elevation: 8,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFFE8E8E8) : const Color(0xFF2A2A2E),
          borderRadius: radiusMd,
        ),
        textStyle: textTheme.labelSmall?.copyWith(
          color: isDark ? Colors.black : Colors.white,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          palette.iconInactive.withValues(alpha: 0.55),
        ),
        trackColor: WidgetStatePropertyAll(palette.subtle),
        radius: const Radius.circular(8),
        thickness: const WidgetStatePropertyAll(4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFFE8E8E8) : palette.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.black : Colors.white,
        ),
        actionTextColor: primary,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
        elevation: 4,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        modalBackgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 12,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.card,
        headerBackgroundColor: primary.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.iconDisabled;
          }
          if (states.contains(WidgetState.selected)) return onPrimary;
          return palette.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStatePropertyAll(palette.textPrimary),
        todayBackgroundColor: WidgetStatePropertyAll(
          primary.withValues(alpha: 0.18),
        ),
        shape: RoundedRectangleBorder(borderRadius: radiusLg),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: palette.card,
        dialBackgroundColor: palette.subtle,
        hourMinuteColor: primary.withValues(alpha: 0.14),
        hourMinuteTextColor: palette.textPrimary,
        dayPeriodColor: primary.withValues(alpha: 0.14),
        dayPeriodTextColor: palette.textPrimary,
        dialHandColor: primary,
        dialTextColor: palette.textPrimary,
        entryModeIconColor: palette.iconActive,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: palette.subtle,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: palette.danger,
        textColor: palette.onDanger,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(palette.card),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: radiusMd),
          ),
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primary,
        scaffoldBackgroundColor: palette.scaffold,
        barBackgroundColor: palette.card,
      ),
    );
  }
}
