import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_routes.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_alert_sound_service.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_request_service.dart';

class AdminNotificationCenterScreen extends StatefulWidget {
  const AdminNotificationCenterScreen({super.key});

  @override
  State<AdminNotificationCenterScreen> createState() =>
      _AdminNotificationCenterScreenState();
}

class _AdminNotificationCenterScreenState
    extends State<AdminNotificationCenterScreen> {
  OpsNotificationCategory? _filter;
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _seeding = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<AdminNotificationService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFFFFAF0);
    final items = svc.filtered(category: _filter, query: _search);
    final sticky = items.where((n) => n.sticky && !n.read).toList();
    final normal = items.where((n) => !n.sticky || n.read).toList();
    final grouped = _groupByDay(normal);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        title: Row(
          children: [
            const Text('Notifications'),
            if (svc.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text('${svc.unreadCount} unread'),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppColor.primary.withValues(alpha: 0.12),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sound settings',
            onPressed: () => _openSoundSheet(context),
            icon: const Icon(Icons.tune_outlined),
          ),
          TextButton(
            onPressed: svc.loading ? null : () => svc.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _seeding ? null : () => _seedTest(context),
        icon: _seeding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.bolt_outlined),
        label: const Text('Test alert'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search notifications…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip('All', null),
                ...OpsNotificationCategory.values.map(
                  (c) => _chip(_label(c), c),
                ),
              ],
            ),
          ),
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    svc.error!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                  ),
                ),
              ),
            ),
          Expanded(
            child: svc.loading
                ? _skeletonList()
                : sticky.isEmpty && grouped.isEmpty
                    ? _emptyState(context)
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                        children: [
                          if (sticky.isNotEmpty) ...[
                            _sectionTitle('Important'),
                            ...sticky.map(
                              (n) => _NotificationTile(
                                notification: n,
                                onTap: () => _open(context, n),
                                onDelete: () => svc.deleteNotification(n),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          for (final entry in grouped.entries) ...[
                            _sectionTitle(entry.key),
                            ...entry.value.map(
                              (n) => _NotificationTile(
                                notification: n,
                                onTap: () => _open(context, n),
                                onDelete: () => svc.deleteNotification(n),
                              ),
                            ),
                          ],
                          if (svc.hasMore)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: OutlinedButton.icon(
                                  onPressed: svc.loadMore,
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Load older'),
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity from user, vendor, and delivery apps appears here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _skeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1200.ms),
    );
  }

  Map<String, List<OpsNotificationModel>> _groupByDay(
    List<OpsNotificationModel> items,
  ) {
    final map = <String, List<OpsNotificationModel>>{};
    final now = DateTime.now();
    for (final n in items) {
      final d = n.createdAt;
      String key;
      if (d == null) {
        key = 'Earlier';
      } else {
        final diff = now.difference(d);
        if (diff.inDays == 0) {
          key = 'Today';
        } else if (diff.inDays == 1) {
          key = 'Yesterday';
        } else {
          key = '${d.day}/${d.month}/${d.year}';
        }
      }
      map.putIfAbsent(key, () => []).add(n);
    }
    return map;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _seedTest(BuildContext context) async {
    setState(() => _seeding = true);
    try {
      await context.read<AdminNotificationService>().seedTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Deploy seedAdminTestNotification'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  void _openSoundSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer<OpsSoundPrefs>(
          builder: (context, prefs, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert sounds',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SwitchListTile(
                    title: const Text('Sound alerts'),
                    value: prefs.enabled,
                    onChanged: prefs.setEnabled,
                  ),
                  Text('Volume', style: TextStyle(color: Colors.grey.shade700)),
                  Slider(
                    value: prefs.volume,
                    onChanged: prefs.enabled ? prefs.setVolume : null,
                  ),
                  const Text(
                    'Preview',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in [
                        'orders',
                        'users',
                        'vendors',
                        'payments',
                        'stock',
                        'delivery',
                        'security',
                      ])
                        ActionChip(
                          label: Text(s),
                          onPressed: () => AdminAlertSoundService.preview(s),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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
    return c.name[0].toUpperCase() + c.name.substring(1);
  }

  Future<void> _open(BuildContext context, OpsNotificationModel n) async {
    final svc = context.read<AdminNotificationService>();
    await svc.markRead(n.id, collectionName: n.collectionName);

    if (!context.mounted) return;

  final type = n.type.toLowerCase();
  if (type.contains('vendor') && n.requestId != null) {
    await _showVendorRequestActions(context, n);
    return;
  }

  final orderId = n.orderId;
  if (orderId != null && orderId.isNotEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .get();
    if (doc.exists && context.mounted) {
      final order = OrderModel.fromFirestore(doc.data()!, doc.id);
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(order: order),
          ),
        );
      }
    }
    return;
  }

  if (n.category == OpsNotificationCategory.users && context.mounted) {
    _popToHomeRoute(context, AdminRoutes.userList);
    return;
  }

  if (n.category == OpsNotificationCategory.delivery && context.mounted) {
    _popToHomeRoute(context, AdminRoutes.deliveryBoyList);
    return;
  }

  if (context.mounted) {
    _showDetailSheet(context, n);
  }
  }

  void _popToHomeRoute(BuildContext context, String route) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    // HomeScreen uses internal navigation — show snackbar hint.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open “$route” from the sidebar.')),
    );
  }

  Future<void> _showVendorRequestActions(
    BuildContext context,
    OpsNotificationModel n,
  ) async {
    final requestId = n.requestId;
    if (requestId == null) return;
    final requestService = context.read<VendorRequestService>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                n.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(n.message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Open Vendor Requests from the sidebar.'),
                    ),
                  );
                },
                child: const Text('View vendor requests'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: requestService.isActionLoading
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await requestService.reject(
                                requestId,
                                'Rejected from notification',
                              );
                            },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: requestService.isActionLoading
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await requestService.approve(requestId);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailSheet(BuildContext context, OpsNotificationModel n) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(n.message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(n.category.name)),
                Chip(label: Text(n.type)),
                if (n.sourceApp.isNotEmpty) Chip(label: Text(n.sourceApp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final OpsNotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color _categoryColor(OpsNotificationCategory c) {
    switch (c) {
      case OpsNotificationCategory.payments:
        return Colors.green.shade700;
      case OpsNotificationCategory.stock:
        return Colors.orange.shade800;
      case OpsNotificationCategory.security:
        return Colors.red.shade700;
      case OpsNotificationCategory.delivery:
        return Colors.blue.shade700;
      case OpsNotificationCategory.users:
        return Colors.purple.shade700;
      case OpsNotificationCategory.vendors:
        return Colors.teal.shade700;
      case OpsNotificationCategory.promotions:
        return Colors.pink.shade700;
      case OpsNotificationCategory.system:
        return Colors.blueGrey.shade700;
      default:
        return AppColor.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final time = relativeTimestamp(n.createdAt);
    final accent = _categoryColor(n.category);
    final urgent = n.isUrgent && !n.read;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: urgent
            ? Colors.red.shade50
            : (n.read ? Colors.white : accent.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: urgent ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.12),
                  child: Icon(
                    iconForCategory(n.category),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: n.read ? Colors.black87 : accent,
                              ),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _tag(n.category.name, accent),
                          if (n.sourceApp.isNotEmpty &&
                              n.sourceApp != 'system')
                            _tag(n.sourceApp, Colors.blueGrey),
                          if (n.priority != OpsNotificationPriority.normal)
                            _tag(
                              n.priority.name,
                              urgent ? Colors.red : accent,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!n.read)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    decoration: BoxDecoration(
                      color: urgent ? Colors.red : accent,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 900.ms,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
