import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/screens/admin_notification_center_screen.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';

class AdminNotificationBell extends StatelessWidget {
  const AdminNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminNotificationService>(
      builder: (context, svc, _) {
        final count = svc.unreadCount;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminNotificationCenterScreen(),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}

/// Top ops bar: bell + sound toggle — embed above dashboard / order screens.
class AdminOpsTopBar extends StatelessWidget {
  const AdminOpsTopBar({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColor.primary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
              ],
            ),
          ),
          Consumer<OpsSoundPrefs>(
            builder: (context, prefs, _) {
              return IconButton(
                tooltip: prefs.enabled ? 'Mute alert sounds' : 'Enable sounds',
                onPressed: prefs.toggle,
                icon: Icon(
                  prefs.enabled
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  color: prefs.enabled ? AppColor.primary : Colors.grey,
                ),
              );
            },
          ),
          const AdminNotificationBell(),
        ],
      ),
    );
  }
}
