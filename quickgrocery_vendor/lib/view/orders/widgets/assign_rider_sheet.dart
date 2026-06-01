import 'package:flutter/material.dart';

import '../../../models/order_model.dart';
import '../../../services/delivery_boy_service.dart';
import '../../../services/order_service.dart';
import '../../../style/app_color.dart';

/// Bottom sheet: search riders, show workload, assign to order.
class AssignRiderSheet {
  AssignRiderSheet._();

  static Future<void> show(
    BuildContext context, {
    required OrderModel order,
    required OrderService orderService,
  }) async {
    final deliveryService = DeliveryBoyService();
    final searchController = TextEditingController();
    var query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign driver',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (v) => setModalState(() => query = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: StreamBuilder<List<RiderOption>>(
                      stream: deliveryService.watchAssignableRidersLive(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
                        }
                        var riders = snap.data ?? [];
                        if (query.isNotEmpty) {
                          final q = query.toLowerCase();
                          riders = riders
                              .where(
                                (r) =>
                                    r.displayName.toLowerCase().contains(q) ||
                                    r.rider.phone.contains(q),
                              )
                              .toList();
                        }
                        if (riders.isEmpty) {
                          return const Center(
                            child: Text('No online delivery partners found'),
                          );
                        }
                        return ListView.separated(
                          itemCount: riders.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final opt = riders[i];
                            final statusColor = opt.isOnline
                                ? Colors.green
                                : Colors.orange;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColor.primary.withValues(alpha: 0.2),
                                child: Text(
                                  opt.displayName.isNotEmpty
                                      ? opt.displayName[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(opt.displayName),
                              subtitle: Text(
                                '${opt.rider.phone}\n'
                                '${opt.statusLabel} · ${opt.activeOrders} active orders',
                              ),
                              isThreeLine: true,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  opt.statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                try {
                                  await orderService.assignDeliveryBoy(
                                    orderId: order.id,
                                    deliveryBoyId: opt.rider.id,
                                    riderName: opt.displayName,
                                    riderPhone: opt.rider.phone,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Assigned ${opt.displayName}',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Assign failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }
}
