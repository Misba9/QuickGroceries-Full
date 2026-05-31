import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_alert_sound_service.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_ops_toast.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_details_drawer.dart';

class AdminNotificationRealtimeHost extends StatefulWidget {
  const AdminNotificationRealtimeHost({super.key, required this.child});

  final Widget child;

  @override
  State<AdminNotificationRealtimeHost> createState() =>
      _AdminNotificationRealtimeHostState();
}

class _AdminNotificationRealtimeHostState
    extends State<AdminNotificationRealtimeHost> {
  Timer? _pollTimer;
  final List<OverlayEntry> _entries = [];
  AdminNotificationService? _svc;
  bool _audioPrimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final svc = context.read<AdminNotificationService>();
    final prefs = context.read<OpsSoundPrefs>();
    svc.attachSoundPrefs(prefs);
    _svc = svc;
    svc.addListener(_onNotificationServiceChanged);
    await svc.prepareClientAlerts();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _drainToasts();
    });
  }

  void _onNotificationServiceChanged() => _drainToasts();

  Future<void> _primeAudio() async {
    if (_audioPrimed) return;
    _audioPrimed = true;
    await AdminAlertSoundService.unlock();
  }

  void _drainToasts() {
    if (!mounted) return;
    final svc = _svc ?? context.read<AdminNotificationService>();
    OpsNotificationModel? n;
    while ((n = svc.consumeToast()) != null) {
      _showToast(n!);
    }
  }

  void _openOrder(String orderId) {
    final orders = context.read<OrderService>().orders;
    if (orders == null) return;
    OrderModel? order;
    for (final o in orders) {
      if (o.id == orderId) {
        order = o;
        break;
      }
    }
    if (order == null || !mounted) return;
    showOrderDetailsDrawer(context, order);
  }

  void _showToast(OpsNotificationModel n) {
    final overlay = Overlay.of(context);
    final orderId = n.orderId;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => AdminOpsToast(
        notification: n,
        onDismiss: () {
          entry.remove();
          _entries.remove(entry);
        },
        onViewOrder: orderId != null && orderId.isNotEmpty
            ? () {
                entry.remove();
                _entries.remove(entry);
                _openOrder(orderId);
              }
            : null,
      ),
    );
    _entries.add(entry);
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) {
        entry.remove();
        _entries.remove(entry);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _svc?.removeListener(_onNotificationServiceChanged);
    for (final e in List<OverlayEntry>.from(_entries)) {
      e.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _primeAudio(),
      child: widget.child,
    );
  }
}
