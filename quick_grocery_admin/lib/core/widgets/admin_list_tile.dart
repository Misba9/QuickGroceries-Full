import 'package:flutter/material.dart';

/// Selected nav item highlight (matches admin cream theme).
const Color kAdminNavSelectedBg = Color(0xFFFFF8E1);

/// [ListTile] with explicit min height and [InkWell] — web-safe hit targets.
class AdminListTile extends StatelessWidget {
  const AdminListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.selected = false,
    this.contentPadding,
    this.minHeight = 56,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool selected;
  final EdgeInsetsGeometry? contentPadding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kAdminNavSelectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: ListTile(
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            dense: dense,
            selected: selected,
            contentPadding: contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      ),
    );
  }
}
