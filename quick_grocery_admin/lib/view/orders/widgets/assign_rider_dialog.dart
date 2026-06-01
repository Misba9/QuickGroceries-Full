import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/rider_assignment_client.dart';

/// Admin dialog — pick a rider or auto-assign nearest eligible partner.
class AssignRiderDialog extends StatefulWidget {
  const AssignRiderDialog({
    super.key,
    required this.order,
    required this.client,
  });

  final OrderModel order;
  final RiderAssignmentClient client;

  static Future<bool?> show(
    BuildContext context, {
    required OrderModel order,
    RiderAssignmentClient? client,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AssignRiderDialog(
        order: order,
        client: client ?? RiderAssignmentClient(),
      ),
    );
  }

  @override
  State<AssignRiderDialog> createState() => _AssignRiderDialogState();
}

class _AssignRiderDialogState extends State<AssignRiderDialog> {
  bool _loading = true;
  bool _assigning = false;
  String? _error;
  List<RankedRider> _riders = const [];
  double _radiusKm = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.client.rankRiders(widget.order.id);
      if (!mounted) return;
      setState(() {
        _riders = result.riders;
        _radiusKm = result.radiusKm;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = RiderAssignmentClient.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _autoAssign() async {
    setState(() => _assigning = true);
    try {
      final r = await widget.client.autoAssign(widget.order.id);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assigned ${r.riderName} (${r.distanceKm.toStringAsFixed(1)} km away)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RiderAssignmentClient.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignManual(RankedRider rider) async {
    setState(() => _assigning = true);
    try {
      await widget.client.assignRider(
        orderId: widget.order.id,
        riderId: rider.id,
        riderName: rider.name,
        riderPhone: rider.phone,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned ${rider.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _assigning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(RiderAssignmentClient.errorMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligible = _riders.where((r) => r.eligible).toList();
    final shortId = widget.order.id.length > 8
        ? widget.order.id.substring(widget.order.id.length - 8).toUpperCase()
        : widget.order.id.toUpperCase();

    return AlertDialog(
      title: Text('Assign rider · #$shortId'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.red))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Eligible riders within ${_radiusKm.toStringAsFixed(0)} km · '
                        'online, active, lowest workload',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (eligible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No eligible riders online in range.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: eligible.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = eligible[i];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColor.primary.withValues(alpha: 0.15),
                                  child: Text('${i + 1}'),
                                ),
                                title: Text(
                                  r.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${r.distanceKm.toStringAsFixed(1)} km · '
                                  '${r.workload} active orders',
                                ),
                                trailing: FilledButton(
                                  onPressed: _assigning
                                      ? null
                                      : () => _assignManual(r),
                                  child: const Text('Assign'),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _assigning ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _assigning || _loading ? null : _autoAssign,
          icon: _assigning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_mode_rounded, size: 18),
          label: const Text('Auto-assign nearest'),
        ),
      ],
    );
  }
}
