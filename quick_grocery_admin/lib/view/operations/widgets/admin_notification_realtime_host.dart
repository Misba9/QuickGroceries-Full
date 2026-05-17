import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_notification_model.dart';
import 'package:quick_grocery_admin/view/operations/services/admin_notification_service.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_sound_prefs.dart';

/// Listens for new admin notifications and shows slide-in toasts + routes sound prefs.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<AdminNotificationService>();
      final prefs = context.read<OpsSoundPrefs>();
      svc.attachSoundPrefs(prefs);
      _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        _drainToasts();
      });
    });
  }

  void _drainToasts() {
    if (!mounted) return;
    final svc = context.read<AdminNotificationService>();
    OpsNotificationModel? n;
    while ((n = svc.consumeToast()) != null) {
      _showToast(n!);
    }
  }

  void _showToast(OpsNotificationModel n) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastBanner(
        notification: n,
        onDismiss: () {
          entry.remove();
          _entries.remove(entry);
        },
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
    for (final e in List<OverlayEntry>.from(_entries)) {
      e.remove();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ToastBanner extends StatelessWidget {
  const _ToastBanner({
    required this.notification,
    required this.onDismiss,
  });

  final OpsNotificationModel notification;
  final VoidCallback onDismiss;

  Color _accent(OpsNotificationCategory c) {
    switch (c) {
      case OpsNotificationCategory.payments:
        return Colors.green.shade700;
      case OpsNotificationCategory.stock:
        return Colors.orange.shade800;
      case OpsNotificationCategory.security:
        return Colors.red.shade700;
      case OpsNotificationCategory.delivery:
        return Colors.blue.shade700;
      default:
        return AppColor.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final top = MediaQuery.paddingOf(context).top + 12;
    final urgent = n.isUrgent;
    return Positioned(
      top: top,
      right: 16,
      left: 16,
      child: Material(
        elevation: urgent ? 12 : 6,
        borderRadius: BorderRadius.circular(14),
        color: urgent ? Colors.red.shade50 : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onDismiss,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: urgent ? Colors.red.shade300 : Colors.grey.shade200,
                width: urgent ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _accent(n.category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: urgent ? Colors.red.shade900 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
