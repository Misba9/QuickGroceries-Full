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
///   • animated active indicator (slides between tabs)
///   • per-tab badge support
///   • spring scale on tap
///   • expects parent [SafeArea] (see [LandingScreen]) — bar uses symmetric
///     padding only; safe inset is not duplicated here.
class ModernBottomNav extends StatelessWidget {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavTab(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.standard,
              width: selected ? 36 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  duration: AppMotion.short,
                  curve: AppMotion.spring,
                  scale: selected ? 1.08 : 1.0,
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: item.svgIcon != null
                        ? SvgPicture.asset(
                            item.svgIcon!,
                            colorFilter:
                                ColorFilter.mode(iconColor, BlendMode.srcIn),
                          )
                        : Icon(
                            selected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: iconColor,
                            size: 22,
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
