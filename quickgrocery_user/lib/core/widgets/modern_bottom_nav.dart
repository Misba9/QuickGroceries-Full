import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';

import '../design/app_tokens.dart';

class ModernBottomNavItem {
  const ModernBottomNavItem({
    required this.label,
    required this.icon,
    this.svgIcon,
    this.activeIcon,
    this.badge,
  });

  final String label;
  final IconData icon;
  final String? svgIcon;
  final IconData? activeIcon;
  final int? badge;
}

/// Premium bottom navigation bar with:
///   • animated sliding indicator under the active tab
///   • per-tab badge support
///   • spring scale on active icon
///   • expects parent [SafeArea] (see [LandingScreen]) — bar uses symmetric
///     padding only; safe inset is not duplicated here.
class ModernBottomNav extends StatefulWidget {
  const ModernBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<ModernBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
          border: Border(
            top: BorderSide(color: AppSurface.border, width: 0.6),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final n = widget.items.length;
            final tabW = constraints.maxWidth / n;
            final idx = widget.currentIndex.clamp(0, n - 1);
            final indicatorLeft = tabW * idx + (tabW - 40) / 2;

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                AnimatedPositioned(
                  duration: AppMotion.medium,
                  curve: AppMotion.spring,
                  top: 4,
                  left: indicatorLeft,
                  width: 40,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.primary.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < n; i++)
                      Expanded(
                        child: _NavTab(
                          item: widget.items[i],
                          selected: i == widget.currentIndex,
                          onTap: () => widget.onTap(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ModernBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColor.primary;
    final iconColor = selected ? Colors.black : Colors.grey.shade500;

    return InkResponse(
      radius: 38,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  duration: AppMotion.short,
                  curve: AppMotion.spring,
                  scale: selected ? 1.1 : 1.0,
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child: item.svgIcon != null
                        ? SvgPicture.asset(
                            item.svgIcon!,
                            colorFilter:
                                ColorFilter.mode(iconColor, BlendMode.srcIn),
                          )
                        : Icon(
                            selected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: selected ? activeColor : iconColor,
                            size: selected ? 24 : 22,
                          ),
                  ),
                ),
                if ((item.badge ?? 0) > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: _Badge(count: item.badge!),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppSurface.textPrimary : AppSurface.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.short,
      child: Container(
        key: ValueKey(count),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: AppSurface.danger,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
