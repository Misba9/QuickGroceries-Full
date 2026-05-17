import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: hasUrgent ? Colors.red.shade700 : null,
              )
                  .animate(
                    target: count > 0 ? 1 : 0,
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .shake(hz: 2, duration: 600.ms),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
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
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        duration: 800.ms,
                      ),
                ),
            ],
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
