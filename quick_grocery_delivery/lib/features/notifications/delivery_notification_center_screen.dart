import 'package:flutter/material.dart';

import '../../core/delivery_notification_router.dart';
import '../../core/delivery_notification_store.dart';

class DeliveryNotificationCenterScreen extends StatelessWidget {
  const DeliveryNotificationCenterScreen({
    super.key,
    required this.riderId,
  });

  final String riderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => DeliveryNotificationStore.markAllRead(riderId),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<DeliveryStoredNotification>>(
        stream: DeliveryNotificationStore.watch(riderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.\nAssignments and cancellations appear here instantly.',
                textAlign: TextAlign.center,
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
                color: n.read ? null : Colors.orange.shade50,
                child: ListTile(
                  leading: Icon(n.icon),
                  title: Text(
                    n.title,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(n.body),
                  onTap: () {
                    DeliveryNotificationRouter.handleNotificationOpen({
                      'type': n.type,
                      'orderId': n.orderId,
                      'title': n.title,
                      'message': n.body,
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
