import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/push_notifications/domain/notification_template_renderer.dart';
import 'package:quick_grocery_admin/view/push_notifications/models/notification_models.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/widgets/push_access_gate.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/widgets/admin_list_tile.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/widgets/push_admin_card.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart'
    show NotificationAdminService, NotificationUserSearchRow;

class PushNotificationsScreen extends StatefulWidget {
  const PushNotificationsScreen({super.key});

  @override
  State<PushNotificationsScreen> createState() =>
      _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends State<PushNotificationsScreen> {
  final _broadcastTitle = TextEditingController();
  final _broadcastMsg = TextEditingController();
  final _deepLink = TextEditingController();
  final _ctaLabel = TextEditingController();
  String _fcmTopic = 'all_users';
  String _targetAudience = 'all_users';
  String _redirectType = 'offers_page';
  String _soundType = 'default';

  final _searchCtrl = TextEditingController();
  final _singleTitle = TextEditingController();
  final _singleMsg = TextEditingController();
  CustomerModel? _picked;
  String? _pickedDocId;

  String? _bannerUrl;

  static const _topics = <String>[
    'all_users',
    'offers',
    'vegetables',
    'dairy',
    'premium_users',
    'active_users',
    'new_users',
  ];

  static const _redirects = <String>[
    'offers_page',
    'product_page',
    'category_page',
    'cart_page',
    'order_page',
    'order_details',
    'home',
  ];

  static const _quick = <String, (String, String)>{
    'free_delivery': (
      'Free delivery',
      'Quick Grocery: Free delivery on your next order today. Open the app.',
    ),
    'weekend': (
      'Weekend offer',
      'Weekend special: extra savings on groceries. Tap to see deals.',
    ),
    'coupon': (
      'Coupon alert',
      'You have a coupon waiting on Quick Grocery. Apply at checkout.',
    ),
    'flash': (
      'Flash sale',
      'Flash sale is live — limited stock. Grab favourites before they sell out.',
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
    _deepLink.dispose();
    _ctaLabel.dispose();
    _searchCtrl.dispose();
    _singleTitle.dispose();
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
      _singleTitle.text = v.$1;
    });
  }

  Future<void> _pickBanner(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (x == null || !context.mounted) return;
    final svc = context.read<NotificationAdminService>();
    try {
      final url = await svc.uploadBannerImage(x);
      if (context.mounted) {
        setState(() => _bannerUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner uploaded')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PushAccessGate(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Push Notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send broadcast or single-user messages via FCM topics.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            const _NotificationAnalyticsRow(),
            const SizedBox(height: 20),
            const _NotificationCampaignsStrip(),
            const SizedBox(height: 20),
            _smartTargetingCard(context),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                if (wide) {
                  final half = (c.maxWidth - 20) / 2;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: half, child: _broadcastCard(context)),
                      const SizedBox(width: 20),
                      SizedBox(width: half, child: _singleUserCard(context)),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _broadcastCard(context),
                    const SizedBox(height: 20),
                    _singleUserCard(context),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _quickActions(context),
            const SizedBox(height: 20),
            AdminSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open Notification History in the sidebar for delivery logs and CTR.',
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _smartTargetingCard(BuildContext context) {
    return PushAdminCard(
      title: 'Smart notifications',
      subtitle:
          'Future-ready: interests, past orders, categories viewed, geo — will plug into Firestore segments.',
      child: Text(
        'Not enabled yet. Broadcast and topic sends above already scale via FCM.',
        style: TextStyle(color: Colors.grey.shade700, height: 1.4),
      ),
    );
  }

  Widget _broadcastCard(BuildContext context) {
    return PushAdminCard(
      title: 'Broadcast & topic push',
      subtitle:
          'Pick an FCM topic and optional rich fields. Users must be subscribed to the topic on their devices.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _broadcastTitle,
            decoration: const InputDecoration(
              labelText: 'Notification title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastMsg,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notification message',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deepLink,
            decoration: const InputDecoration(
              labelText: 'Deep link (optional, e.g. quickgrocery://offers)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctaLabel,
            decoration: const InputDecoration(
              labelText: 'CTA label (optional, shown in payload)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fcmTopic,
                  decoration: const InputDecoration(
                    labelText: 'FCM topic',
                    border: OutlineInputBorder(),
                  ),
                  items: _topics
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _fcmTopic = v ?? 'all_users'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _redirectType,
                  decoration: const InputDecoration(
                    labelText: 'Redirect type',
                    border: OutlineInputBorder(),
                  ),
                  items: _redirects
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _redirectType = v ?? 'offers_page'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _soundType,
                  decoration: const InputDecoration(
                    labelText: 'Sound hint (data payload)',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('default')),
                    DropdownMenuItem(value: 'orders', child: Text('orders')),
                    DropdownMenuItem(value: 'offers', child: Text('offers')),
                    DropdownMenuItem(
                      value: 'delivery',
                      child: Text('delivery'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _soundType = v ?? 'default'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickBanner(context),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _bannerUrl == null ? 'Upload banner' : 'Change banner',
                  ),
                ),
              ),
            ],
          ),
          if (_bannerUrl != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              _bannerUrl!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          const Text('Audience tag (metadata for logs / future rules)'),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all_users', label: Text('All')),
              ButtonSegment(value: 'active_users', label: Text('Active')),
              ButtonSegment(value: 'new_users', label: Text('New')),
              ButtonSegment(value: 'premium_users', label: Text('Premium')),
            ],
            selected: {_targetAudience},
            onSelectionChanged: (s) =>
                setState(() => _targetAudience = s.first),
          ),
          const SizedBox(height: 12),
          _BroadcastMessagePreview(controller: _broadcastMsg),
          const SizedBox(height: 12),
          _BroadcastSendActions(
            onSendNow: () => _sendBroadcast(context, schedule: false),
            onSchedule: () => _sendBroadcast(context, schedule: true),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast(BuildContext context, {required bool schedule}) async {
    final svc = context.read<NotificationAdminService>();
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
      if (scheduledAt != null) {
        final id = await svc.scheduleTopicPush(
          title: title,
          message: message,
          scheduledAt: scheduledAt,
          topic: _fcmTopic,
          targetAudience: _targetAudience,
          imageUrl: _bannerUrl,
          deepLink: _deepLink.text.trim().isEmpty ? null : _deepLink.text.trim(),
          redirectType: _redirectType,
          ctaLabel: _ctaLabel.text.trim().isEmpty ? null : _ctaLabel.text.trim(),
          soundType: _soundType == 'default' ? null : _soundType,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Scheduled. Campaign: $id')),
          );
        }
      } else {
        await svc.sendTopicPush(
          title: title,
          message: message,
          topic: _fcmTopic,
          targetAudience: _targetAudience,
          imageUrl: _bannerUrl,
          deepLink: _deepLink.text.trim().isEmpty ? null : _deepLink.text.trim(),
          redirectType: _redirectType,
          ctaLabel: _ctaLabel.text.trim().isEmpty ? null : _ctaLabel.text.trim(),
          soundType: _soundType == 'default' ? null : _soundType,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Push sent via FCM')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Widget _singleUserCard(BuildContext context) {
    return PushAdminCard(
      title: 'Individual user',
      subtitle: 'Search by name, email, or phone — sends to stored FCM token.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Search user',
              border: const OutlineInputBorder(),
              helperText: 'Type 2+ characters, then search',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _pickUserSheet(context),
              ),
            ),
            onSubmitted: (_) => _pickUserSheet(context),
          ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            AdminListTile(
              title: Text(_picked!.name),
              subtitle: Text('${_picked!.email} · ${_picked!.phoneNumber}'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _picked = null;
                  _pickedDocId = null;
                }),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _singleTitle,
            decoration: const InputDecoration(
              labelText: 'Title',
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
            child: _SingleUserSendButton(
              onSend: () => _sendSingleUser(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSingleUser(BuildContext context) async {
    final svc = context.read<NotificationAdminService>();
    final uid = _pickedDocId ?? _picked?.id;
    final title = _singleTitle.text.trim();
    final message = _singleMsg.text.trim();
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a user first')),
      );
      return;
    }
    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message required')),
      );
      return;
    }
    final body = renderNotificationTemplate(message, {
      'userName': _picked?.name ?? 'there',
      'orderId': '—',
      'userId': uid,
    });
    try {
      await svc.sendSingleUserPush(
        userId: uid,
        title: title,
        message: body,
        imageUrl: _bannerUrl,
        deepLink: _deepLink.text.trim().isEmpty ? null : _deepLink.text.trim(),
        redirectType: _redirectType,
        ctaLabel: _ctaLabel.text.trim().isEmpty ? null : _ctaLabel.text.trim(),
        soundType: _soundType == 'default' ? null : _soundType,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Push sent')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _pickUserSheet(BuildContext context) async {
    final svc = context.read<NotificationAdminService>();
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type at least 2 characters')),
      );
      return;
    }
    final list = await svc.searchCustomers(q);
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<NotificationUserSearchRow>(
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
            return AdminListTile(
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
      });
    }
  }

  Widget _quickActions(BuildContext context) {
    return PushAdminCard(
      title: 'Quick action templates',
      subtitle: 'Prefills title and message — review topics and deep links before sending.',
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

/// Analytics chips — isolated from form [setState] and service [busy] updates.
class _NotificationAnalyticsRow extends StatelessWidget {
  const _NotificationAnalyticsRow();

  @override
  Widget build(BuildContext context) {
    final stream =
        context.read<NotificationAdminService>().watchLogs(limit: 500);
    return StreamBuilder<List<NotificationLog>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const SizedBox(
            height: 72,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final logs = snap.data ?? const <NotificationLog>[];
        final sent = logs.where((e) => e.status == 'sent').length;
        final failed = logs.where((e) => e.status == 'failed').length;
        final opens = logs.fold<int>(0, (a, e) => a + (e.openedCount ?? 0));
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _AnalyticsStatChip(
              label: 'Recent logs',
              value: '${logs.length}',
              icon: Icons.list_alt,
            ),
            _AnalyticsStatChip(
              label: 'Sent',
              value: '$sent',
              icon: Icons.check_circle_outline,
            ),
            _AnalyticsStatChip(
              label: 'Failed',
              value: '$failed',
              icon: Icons.error_outline,
            ),
            _AnalyticsStatChip(
              label: 'Opens (sum)',
              value: '$opens',
              icon: Icons.ads_click_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _AnalyticsStatChip extends StatelessWidget {
  const _AnalyticsStatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCampaignsStrip extends StatelessWidget {
  const _NotificationCampaignsStrip();

  @override
  Widget build(BuildContext context) {
    final stream =
        context.read<NotificationAdminService>().watchRecentCampaigns();
    return StreamBuilder<List<NotificationCampaign>>(
      stream: stream,
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) return const SizedBox.shrink();
        return PushAdminCard(
          title: 'Recent campaigns',
          subtitle:
              'Scheduled topic or single-user sends tracked in Firestore.',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: list.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Chip(
                    avatar: Icon(
                      c.status == 'completed'
                          ? Icons.check_circle
                          : c.status == 'failed'
                              ? Icons.error_outline
                              : Icons.schedule,
                      size: 18,
                    ),
                    label: Text(
                      '${c.title} · ${c.status} · sent ${c.sentCount}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Rebuilds only the preview box when the message controller changes.
class _BroadcastMessagePreview extends StatefulWidget {
  const _BroadcastMessagePreview({required this.controller});

  final TextEditingController controller;

  @override
  State<_BroadcastMessagePreview> createState() =>
      _BroadcastMessagePreviewState();
}

class _BroadcastMessagePreviewState extends State<_BroadcastMessagePreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final preview = renderNotificationTemplate(widget.controller.text, {
      'userName': 'Priya',
      'orderId': 'QG-48291',
      'userId': 'cust_demo',
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              style: const TextStyle(fontFamily: 'monospace', height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}

class _BroadcastSendActions extends StatelessWidget {
  const _BroadcastSendActions({
    required this.onSendNow,
    required this.onSchedule,
  });

  final VoidCallback onSendNow;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationAdminService, bool>(
      selector: (_, s) => s.busy,
      builder: (context, busy, _) {
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black87,
              ),
              onPressed: busy ? null : onSendNow,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(busy ? 'Sending…' : 'Send notification'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : onSchedule,
              icon: const Icon(Icons.schedule_rounded),
              label: const Text('Schedule notification'),
            ),
          ],
        );
      },
    );
  }
}

class _SingleUserSendButton extends StatelessWidget {
  const _SingleUserSendButton({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Selector<NotificationAdminService, bool>(
      selector: (_, s) => s.busy,
      builder: (context, busy, _) {
        return FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.black87,
          ),
          onPressed: busy ? null : onSend,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_active_outlined),
          label: Text(busy ? 'Sending…' : 'Send push'),
        );
      },
    );
  }
}
