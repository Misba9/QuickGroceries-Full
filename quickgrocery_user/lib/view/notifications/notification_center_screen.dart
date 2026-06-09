import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/realtime/models/notification_item.dart';
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';
import 'package:quickgrocery/realtime/utils/notification_navigation.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || uid.isEmpty || _markingAll) return;
    setState(() => _markingAll = true);
    HapticFeedback.lightImpact();
    try {
      await ref.read(realtimeNotificationRepositoryProvider).markAllAsRead(uid);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.notification_center)),
        body: Center(child: Text(context.l10n.signInForNotifications)),
      );
    }

    final async = ref.watch(notificationsStreamProvider);
    final unread = ref.watch(unreadNotificationsCountProvider).when(
          data: (n) => n,
          loading: () => 0,
          error: (_, __) => 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notification_center),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: _markingAll
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColor.primary,
                      ),
                    )
                  : Text(context.l10n.mark_all_read),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(context.l10n.something_went_wrong)),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet. Offers and orders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _CenterNotificationTile(item: items[i]),
          );
        },
      ),
    );
  }
}

class _CenterNotificationTile extends ConsumerWidget {
  const _CenterNotificationTile({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.read;

    return Material(
      color: unread
          ? AppColor.primary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          item.title.isEmpty ? 'Quick Grocery' : item.title,
          style: TextStyle(
            fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        subtitle: Text(item.body),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppSurface.danger,
                  shape: BoxShape.circle,
                ),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () async {
          final uid = ref.read(currentUidProvider);
          if (uid != null && uid.isNotEmpty && !item.read) {
            await ref
                .read(realtimeNotificationRepositoryProvider)
                .markAsRead(uid, item.id);
          }
          if (!context.mounted) return;
          await handlePushNavigation(notificationPushData(item));
        },
      ),
    );
  }
}
