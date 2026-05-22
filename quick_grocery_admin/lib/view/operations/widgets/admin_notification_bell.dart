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
        final hasUrgent = svc.recent.any((n) => !n.read && n.isUrgent);
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.of(context).push(
              PageRouteBuilder<void>(
                pageBuilder: (_, __, ___) =>
                    const AdminNotificationCenterScreen(),
                transitionsBuilder: (_, anim, __, child) {
                  final offset = Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  );
                  return SlideTransition(position: offset, child: child);
                },
              ),
            );
          },
          icon: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: hasUrgent ? Colors.red.shade700 : null,
                ),
                if (count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: hasUrgent ? Colors.red : AppColor.primary,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (hasUrgent ? Colors.red : AppColor.primary)
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// In-page section header (sound toggle).
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
        ],
      ),
    );
  }
}
