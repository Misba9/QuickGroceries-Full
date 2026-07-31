import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/widgets/global_floating_cart_widget.dart';

import '../design/app_tokens.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Bottom navigation: Home, Categories, **Offers FAB**, Ask AI, Profile.
class PremiumFiveTabNav extends StatelessWidget {
  const PremiumFiveTabNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.offersBadgeCount,
  });

  /// Total height of the bottom nav including safe-area inset.
  static double tabBarHeight(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return safeBottom + 70;
  }

  /// [Positioned.bottom] for the floating cart above this bar (+ 12px gap).
  static double floatingOverlayBodyBottom(BuildContext context) =>
      tabBarHeight(context) + GlobalFloatingCartWidget.gapAboveTabBar;

  /// Tab index in [HomeProvider.pages]: 0–4 (Offers is **2**).
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? offersBadgeCount;

  @override
  Widget build(BuildContext context) {
    final badge = offersBadgeCount ?? 0;
    final surface = AppSurface.of(context);
    return Material(
      color: surface.card,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: surface.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkTheme ? 0.35 : 0.07),
              blurRadius: 28,
              offset: const Offset(0, -8),
            ),
          ],
          border: Border(
            top: BorderSide(color: surface.border, width: 0.6),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 2),
            child: SizedBox(
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _SideTab(
                          label: context.l10n.nav_home,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          selected: currentIndex == 0,
                          onTap: () => onTap(0),
                          indicatorLeft: true,
                        ),
                      ),
                      Expanded(
                        child: _SideTab(
                          label: context.l10n.nav_categories,
                          icon: Icons.grid_view_outlined,
                          activeIcon: Icons.grid_view_rounded,
                          selected: currentIndex == 1,
                          onTap: () => onTap(1),
                          indicatorCenter: true,
                        ),
                      ),
                      const SizedBox(width: 76),
                      Expanded(
                        child: _SideTab(
                          label: context.l10n.nav_ai,
                          icon: Icons.smart_toy_outlined,
                          activeIcon: Icons.smart_toy_rounded,
                          selected: currentIndex == 3,
                          onTap: () => onTap(3),
                          indicatorCenter: true,
                        ),
                      ),
                      Expanded(
                        child: _SideTab(
                          label: context.l10n.nav_profile,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          selected: currentIndex == 4,
                          onTap: () => onTap(4),
                          indicatorRight: true,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: -18,
                    child: _OffersFab(
                      selected: currentIndex == 2,
                      badge: badge,
                      onTap: () => onTap(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  const _SideTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
    this.indicatorLeft = false,
    this.indicatorCenter = false,
    this.indicatorRight = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;
  final bool indicatorLeft;
  final bool indicatorCenter;
  final bool indicatorRight;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final activeColor = AppColor.primary;
    final iconColor =
        selected ? activeColor : surface.iconInactive;

    return InkResponse(
      radius: 40,
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          AnimatedOpacity(
            duration: AppMotion.short,
            opacity: selected ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Align(
                alignment: indicatorLeft
                    ? Alignment.topLeft
                    : indicatorRight
                        ? Alignment.topRight
                        : Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: indicatorLeft ? 18 : 0,
                    right: indicatorRight ? 18 : 0,
                  ),
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: AppMotion.short,
                  curve: AppMotion.spring,
                  scale: selected ? 1.08 : 1.0,
                  child: Icon(
                    selected ? activeIcon : icon,
                    color: iconColor,
                    size: selected ? 23 : 21,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color:
                        selected ? AppSurface.of(context).textPrimary : AppSurface.of(context).textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersFab extends StatefulWidget {
  const _OffersFab({
    required this.selected,
    required this.onTap,
    required this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_OffersFab> createState() => _OffersFabState();
}

class _OffersFabState extends State<_OffersFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: scale,
        builder: (context, child) => Transform.scale(
          scale: widget.selected ? scale.value : 1.0,
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.brand(),
                boxShadow: [
                  ...AppShadow.primaryGlow,
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppSurface.of(context).card, width: 3),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: Colors.white,
                size: widget.selected ? 28 : 26,
              ),
            ),
            if (widget.badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppSurface.of(context).danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppSurface.of(context).card,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.badge > 99 ? '99+' : '${widget.badge}',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppSurface.of(context).onDanger,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
