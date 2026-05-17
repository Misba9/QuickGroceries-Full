import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/push_notifications/models/notification_models.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/widgets/push_access_gate.dart';
import 'package:quick_grocery_admin/view/push_notifications/presentation/widgets/push_admin_card.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart';

class NotificationTemplatesScreen extends StatelessWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PushAccessGate(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Templates',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reusable copy with variables: {{userName}}, {{orderId}}, {{userId}}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.black87,
                ),
                onPressed: () => _openEditor(context, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add template'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<NotificationTemplate>>(
                stream: context
                    .read<NotificationAdminService>()
                    .watchTemplates(),
                builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list = snap.data!;
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'No templates yet.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      return LayoutBuilder(
                        builder: (context, c) {
                          final cross = c.maxWidth > 1100
                              ? 3
                              : c.maxWidth > 700
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cross,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final t = list[i];
                              return PushAdminCard(
                                title: t.title,
                                subtitle: t.type,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () =>
                                          _openEditor(context, t),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text(
                                              'Delete template?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              FilledButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (ok == true) {
                                          await context
                                              .read<NotificationAdminService>()
                                              .deleteTemplate(t.id);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Deleted'),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (t.imageUrl != null &&
                                        t.imageUrl!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            t.imageUrl!,
                                            height: 56,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        t.message,
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(height: 1.35),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    NotificationTemplate? existing,
  ) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final msgCtrl = TextEditingController(text: existing?.message ?? '');
    final typeCtrl = TextEditingController(text: existing?.type ?? 'promotion');
    final imageCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final svc = context.read<NotificationAdminService>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'New template' : 'Edit template'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Type (e.g. promotion, transactional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Banner image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.black87,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final img = imageCtrl.text.trim();
      await svc.saveTemplate(
        id: existing?.id,
        title: titleCtrl.text.trim(),
        message: msgCtrl.text.trim(),
        type: typeCtrl.text.trim().isEmpty ? 'promotion' : typeCtrl.text.trim(),
        imageUrl: img.isEmpty ? null : img,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved')),
      );
    }
  }
}
