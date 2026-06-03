import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/widgets/admin_list_tile.dart';
/// Sidebar / nav row with explicit size — safe for Flutter Web hit testing.
class AdminNavItem extends StatelessWidget {
  const AdminNavItem({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.leadingDot = false,
    this.indent = 0,
    this.height = 48,
    this.badgeCount = 0,
    this.collapsed = false,
    this.tooltip,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? icon;
  final bool leadingDot;
  final double indent;
  final double height;
  final int badgeCount;
  final bool collapsed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tip = tooltip ?? label;

    Widget item = Padding(
        padding: EdgeInsets.only(left: collapsed ? 0 : indent, bottom: 4),
        child: Material(
          color: selected ? kAdminNavSelectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: collapsed
                  ? _CollapsedContent(
                      icon: icon,
                      leadingDot: leadingDot,
                      selected: selected,
                      badgeCount: badgeCount,
                    )
                  : _ExpandedContent(
                      icon: icon,
                      leadingDot: leadingDot,
                      selected: selected,
                      label: label,
                      badgeCount: badgeCount,
                    ),
            ),
          ),
        ),
      );

    if (collapsed) {
      item = Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 400),
        child: item,
      );
    }

    return item;
  }
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.icon,
    required this.leadingDot,
    required this.selected,
    required this.label,
    required this.badgeCount,
  });

  final Widget? icon;
  final bool leadingDot;
  final bool selected;
  final String label;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            SizedBox(width: 22, height: 22, child: icon),
            const SizedBox(width: 12),
          ] else if (leadingDot) ...[
            SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
          ),
          if (badgeCount > 0) _Badge(count: badgeCount),
        ],
      ),
    );
  }
}

class _CollapsedContent extends StatelessWidget {
  const _CollapsedContent({
    required this.icon,
    required this.leadingDot,
    required this.selected,
    required this.badgeCount,
  });

  final Widget? icon;
  final bool leadingDot;
  final bool selected;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (icon != null) {
      leading = SizedBox(width: 22, height: 22, child: icon);
    } else if (leadingDot) {
      leading = Icon(
        Icons.circle,
        size: 10,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade500,
      );
    }

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (leading != null) leading,
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -6,
              child: _Badge(count: badgeCount, compact: true),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, this.compact = false});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
