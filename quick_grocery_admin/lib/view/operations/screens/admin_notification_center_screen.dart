import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationCenterScreen extends StatefulWidget {
  const AdminNotificationCenterScreen({super.key});

  @override
  State<AdminNotificationCenterScreen> createState() =>
      _AdminNotificationCenterScreenState();
}

class _AdminNotificationCenterScreenState
    extends State<AdminNotificationCenterScreen> {
  OpsNotificationCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AdminNotificationService>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      appBar: AppBar(
        title: const Text('Notification center'),
        actions: [
          TextButton(
            onPressed: () => svc.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _chip('All', null),
                ...OpsNotificationCategory.values.map(
                  (c) => _chip(_label(c), c),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OpsNotificationModel>>(
              stream: svc.streamPage(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                var items = snap.data ?? [];
                if (_filter != null) {
                  items = items.where((n) => n.category == _filter).toList();
                }
                if (items.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return _NotificationTile(
                      notification: n,
                      onTap: () => _open(context, n),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, OpsNotificationCategory? cat) {
    final selected = _filter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = cat),
        selectedColor: AppColor.primary.withValues(alpha: 0.15),
      ),
    );
  }

  String _label(OpsNotificationCategory c) {
    switch (c) {
      case OpsNotificationCategory.orders:
        return 'Orders';
      case OpsNotificationCategory.users:
        return 'Users';
      case OpsNotificationCategory.vendors:
        return 'Vendors';
      case OpsNotificationCategory.payments:
        return 'Payments';
      case OpsNotificationCategory.stock:
        return 'Stock';
      case OpsNotificationCategory.delivery:
        return 'Delivery';
      case OpsNotificationCategory.system:
        return 'System';
    }
  }

  Future<void> _open(BuildContext context, OpsNotificationModel n) async {
    final svc = context.read<AdminNotificationService>();
    await svc.markRead(n.id);
    final orderId = n.orderId;
    if (orderId != null && orderId.isNotEmpty && context.mounted) {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (doc.exists && context.mounted) {
        final order = OrderModel.fromFirestore(doc.data()!, doc.id);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OrderDetailsScreen(order: order),
            ),
          );
        }
      }
    }
    if (n.soundAlert && context.mounted) {
      final prefs = context.read<OpsSoundPrefs>();
      if (prefs.enabled && kIsWeb == false) {
        // System sound handled by OS on mobile admin builds; web uses visual only.
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final OpsNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final time = n.createdAt != null
        ? DateFormat('MMM d · HH:mm').format(n.createdAt!)
        : '';
    return Material(
      color: n.read ? Colors.white : AppColor.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _icon(n.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: n.read ? Colors.black87 : AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(n.message),
                    if (time.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!n.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColor.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Icon _icon(OpsNotificationCategory c) {
    IconData data;
    switch (c) {
      case OpsNotificationCategory.users:
        data = Icons.person_add_outlined;
        break;
      case OpsNotificationCategory.vendors:
        data = Icons.storefront_outlined;
        break;
      case OpsNotificationCategory.stock:
        data = Icons.inventory_2_outlined;
        break;
      case OpsNotificationCategory.delivery:
        data = Icons.delivery_dining_outlined;
        break;
      case OpsNotificationCategory.payments:
        data = Icons.payments_outlined;
        break;
      case OpsNotificationCategory.system:
        data = Icons.insights_outlined;
        break;
      default:
        data = Icons.shopping_bag_outlined;
    }
    return Icon(data, color: AppColor.primary);
  }
}
