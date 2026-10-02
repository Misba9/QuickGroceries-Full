import 'package:flutter/material.dart';

import '../../../core/vendor_notification_router.dart';
import '../../../core/vendor_notification_store.dart';
import '../../../style/app_color.dart';

/// Firestore-backed notification hub for vendor order events.
class VendorNotificationCenter extends StatelessWidget {
  const VendorNotificationCenter({
    super.key,
    required this.vendorId,
  });

  final String vendorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => VendorNotificationStore.markAllRead(vendorId),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<VendorStoredNotification>>(
        stream: VendorNotificationStore.watch(vendorId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.\nNew orders will appear here instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final n = items[index];
              return Card(
                color: n.read ? null : Colors.green.shade50,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColor.primary.withValues(alpha: 0.35),
                    child: Icon(n.icon, color: Colors.black87),
                  ),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n.body),
                      if (n.orderId.isNotEmpty)
                        Text(
                          'Order #${n.orderId.substring(0, 8)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  onTap: () async {
                    await VendorNotificationStore.markRead(vendorId, n.id);
                    if (!context.mounted) return;
                    await VendorNotificationRouter.handleNotificationOpen({
                      'type': n.type,
                      'orderId': n.orderId,
                      'title': n.title,
                      'message': n.body,
                      'targetScreen': n.orderId.isNotEmpty
                          ? 'order_detail'
                          : 'orders_tab',
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
