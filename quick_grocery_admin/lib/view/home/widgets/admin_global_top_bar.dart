import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_top_bar_actions.dart';
/// Fixed admin header — title + notification + logout on all main routes.
class AdminGlobalTopBar extends StatelessWidget {
  const AdminGlobalTopBar({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
  });

  final String title;
  final Widget? leading;
  final String? subtitle;

  static const double barHeight = 64;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const AdminTopBarActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
