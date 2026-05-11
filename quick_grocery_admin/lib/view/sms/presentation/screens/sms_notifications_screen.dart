import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/sms/domain/sms_template_renderer.dart';
import 'package:quick_grocery_admin/view/sms/models/sms_models.dart';
import 'package:quick_grocery_admin/view/sms/presentation/widgets/sms_access_gate.dart';
import 'package:quick_grocery_admin/view/sms/presentation/widgets/sms_admin_card.dart';
import 'package:quick_grocery_admin/view/sms/services/sms_admin_service.dart'
    show SmsAdminService, SmsUserSearchRow;

class SmsNotificationsScreen extends StatefulWidget {
  const SmsNotificationsScreen({super.key});

  @override
  State<SmsNotificationsScreen> createState() => _SmsNotificationsScreenState();
}

class _SmsNotificationsScreenState extends State<SmsNotificationsScreen> {
  final _broadcastTitle = TextEditingController();
  final _broadcastMsg = TextEditingController();
  String _targetType = 'all_users';

  final _searchCtrl = TextEditingController();
  final _singlePhone = TextEditingController();
  final _singleMsg = TextEditingController();
  CustomerModel? _picked;
  String? _pickedDocId;

  String? _lastCampaignId;

  static const _quick = <String, (String, String)>{
    'free_delivery': (
      'Free delivery',
      'Quick Grocery: Free delivery on your next order today. Shop now!',
    ),
    'weekend': (
      'Weekend offer',
      'Weekend special: extra savings on groceries. Open the app to see deals.',
    ),
    'coupon': (
      'Coupon alert',
      'You have a coupon waiting on Quick Grocery. Tap to apply at checkout.',
    ),
    'flash': (
      'Flash sale',
      'Flash sale is live — limited stock. Grab your favourites before they sell out.',
    ),
    'delay': (
      'Delivery update',
      'Hi {{userName}}, your order may arrive a little later than planned. Thanks for your patience.',
    ),
    'festival': (
      'Festival sale',
      'Festival sale: big discounts across categories. Shop Quick Grocery now.',
    ),
  };

  @override
  void dispose() {
    _broadcastTitle.dispose();
    _broadcastMsg.dispose();
    _searchCtrl.dispose();
    _singlePhone.dispose();
    _singleMsg.dispose();
    super.dispose();
  }

  void _applyQuick(String key) {
    final v = _quick[key];
    if (v == null) return;
    setState(() {
      _broadcastTitle.text = v.$1;
      _broadcastMsg.text = v.$2;
      _singleMsg.text = v.$2;
    });
  }

  int _smsUnits(String body) {
    final units = body.runes.length;
    final unicode = body.runes.any((r) => r > 0x7F);
    final per = unicode ? 70 : 160;
    return ((units / per).ceil()).clamp(1, 999);
  }

  @override
  Widget build(BuildContext context) {
    final msg = _broadcastMsg.text;
    final units = _smsUnits(msg);
    final preview = renderSmsTemplate(msg, {
      'userName': 'Priya',
      'orderId': 'QG-48291',
      'userId': 'cust_demo',
    });

    return SmsAccessGate(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS Notifications',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 6),
                Text(
                  'Broadcasts are queued on the server, sent in batches, and retried by background workers.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                _analyticsRow(context),
                const SizedBox(height: 20),
                _campaignsStrip(context),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth > 900;
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _broadcastCard(context, preview, units)),
                          const SizedBox(width: 20),
                          Expanded(child: _singleUserCard(context)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _broadcastCard(context, preview, units),
                        const SizedBox(height: 20),
                        _singleUserCard(context),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _quickActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _analyticsRow(BuildContext context) {
    return Consumer<SmsAdminService>(
      builder: (context, svc, _) {
        return StreamBuilder<List<SmsLog>>(
          stream: svc.watchLogs(limit: 500),
          builder: (context, snap) {
            final logs = snap.data ?? const <SmsLog>[];
            final sent = logs.where((e) => e.status == 'sent').length;
            final failed = logs.where((e) => e.status == 'failed').length;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statChip('Recent rows', '${logs.length}', Icons.list_alt),
                _statChip('Sent (sample)', '$sent', Icons.check_circle_outline),
                _statChip('Failed (sample)', '$failed', Icons.error_outline),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statChip(String label, String value, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColor.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignsStrip(BuildContext context) {
    return Consumer<SmsAdminService>(
      builder: (context, svc, _) {
        return StreamBuilder<List<SmsCampaign>>(
          stream: svc.watchRecentCampaigns(),
          builder: (context, snap) {
            final list = snap.data ?? const [];
            if (list.isEmpty) return const SizedBox.shrink();
            return SmsAdminCard(
              title: 'Recent campaigns',
              subtitle: 'Background worker processes queued items every few minutes.',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: list.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ActionChip(
                        avatar: Icon(
                          c.status == 'completed'
                              ? Icons.check_circle
                              : Icons.hourglass_top,
                          size: 18,
                        ),
                        label: Text(
                          '${c.title} · ${c.status} · ${c.sentCount}/${c.failedCount}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () async {
                          if (c.status == 'completed') return;
                          try {
                            await svc.resumeBroadcast(c.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Processed batch for ${c.title}')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _broadcastCard(
    BuildContext context,
    String preview,
    int units,
  ) {
    return SmsAdminCard(
      title: 'Broadcast SMS',
      subtitle: 'Title is stored on the campaign for analytics; SMS body is what users receive.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _broadcastTitle,
            decoration: const InputDecoration(
              labelText: 'Message title',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastMsg,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'SMS message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            '${_broadcastMsg.text.runes.length} characters · ~$units SMS part(s)',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            'Preview (sample names)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                preview.isEmpty ? '…' : preview,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Send to'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'all_users',
                label: Text('All'),
                tooltip: 'All users with a phone',
              ),
              ButtonSegment(
                value: 'active_users',
                label: Text('Active'),
                tooltip: 'Not blocked',
              ),
              ButtonSegment(
                value: 'new_users',
                label: Text('New'),
                tooltip: 'Joined in last ~30 days',
              ),
            ],
            selected: {_targetType},
            onSelectionChanged: (s) =>
                setState(() => _targetType = s.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.black87,
                ),
                onPressed: context.watch<SmsAdminService>().busy
                    ? null
                    : () => _sendBroadcast(context, schedule: false),
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send SMS'),
              ),
              OutlinedButton.icon(
                onPressed: context.watch<SmsAdminService>().busy
                    ? null
                    : () => _sendBroadcast(context, schedule: true),
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Schedule SMS'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast(BuildContext context, {required bool schedule}) async {
    final svc = context.read<SmsAdminService>();
    final title = _broadcastTitle.text.trim();
    final message = _broadcastMsg.text.trim();
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add title and message')),
      );
      return;
    }
    DateTime? scheduledAt;
    if (schedule) {
      final d = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (d == null || !context.mounted) return;
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (t == null || !context.mounted) return;
      scheduledAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    }
    try {
      final id = await svc.enqueueBroadcast(
        title: title,
        message: message,
        targetType: _targetType,
        scheduledAt: scheduledAt,
      );
      _lastCampaignId = id.isEmpty ? null : id;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              scheduledAt != null
                  ? 'Campaign scheduled. ID: $id'
                  : 'Campaign queued. ID: $id',
            ),
            action: SnackBarAction(
              label: 'Process now',
              onPressed: () async {
                if (_lastCampaignId == null) return;
                try {
                  await svc.resumeBroadcast(_lastCampaignId!);
                } catch (_) {}
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _singleUserCard(BuildContext context) {
    return SmsAdminCard(
      title: 'Send to one customer',
      subtitle: 'Search by name, phone, or email — pick a row to autofill the phone field.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Search user',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _pickUserSheet(context),
              ),
            ),
            onSubmitted: (_) => _pickUserSheet(context),
          ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_picked!.name),
              subtitle: Text('${_picked!.email} · ${_picked!.phoneNumber}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _picked = null;
                  _pickedDocId = null;
                  _singlePhone.clear();
                }),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _singlePhone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _singleMsg,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black87,
              ),
              onPressed: context.watch<SmsAdminService>().busy
                  ? null
                  : () async {
                      final svc = context.read<SmsAdminService>();
                      final phone = _singlePhone.text.trim();
                      final message = _singleMsg.text.trim();
                      if (phone.isEmpty || message.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Phone and message required'),
                          ),
                        );
                        return;
                      }
                      final body = renderSmsTemplate(message, {
                        'userName': _picked?.name ?? 'there',
                        'orderId': '—',
                        'userId': _picked?.id ?? '',
                      });
                      try {
                        await svc.sendSingle(
                          phone: phone,
                          message: body,
                          userId: _pickedDocId ?? _picked?.id,
                          title: _broadcastTitle.text.trim().isEmpty
                              ? 'Direct SMS'
                              : _broadcastTitle.text.trim(),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('SMS sent')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('Send SMS'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickUserSheet(BuildContext context) async {
    final svc = context.read<SmsAdminService>();
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type at least 2 characters')),
      );
      return;
    }
    final list = await svc.searchCustomers(q);
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<SmsUserSearchRow>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matches in the first 300 customers. Refine search.'),
          );
        }
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final row = list[i];
            final c = row.customer;
            return ListTile(
              title: Text(c.name),
              subtitle: Text('${c.phoneNumber} · ${c.email}'),
              onTap: () => Navigator.pop(ctx, row),
            );
          },
        );
      },
    );
    if (picked != null) {
      setState(() {
        _pickedDocId = picked.docId;
        _picked = picked.customer;
        _singlePhone.text = picked.customer.phoneNumber;
      });
    }
  }

  Widget _quickActions(BuildContext context) {
    return SmsAdminCard(
      title: 'Quick SMS actions',
      subtitle: 'Prefills broadcast + single message fields — review before sending.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(context, 'Free delivery', 'free_delivery'),
          _chip(context, 'Weekend offer', 'weekend'),
          _chip(context, 'Coupon alert', 'coupon'),
          _chip(context, 'Flash sale', 'flash'),
          _chip(context, 'Delivery delayed', 'delay'),
          _chip(context, 'Festival sale', 'festival'),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String key) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyQuick(key),
    );
  }
}
