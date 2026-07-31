import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_profile_screen.dart';
import 'package:quick_grocery_admin/view/customers/services/cod_restriction_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';

class CustomerRowActions extends StatelessWidget {
  const CustomerRowActions({
    super.key,
    required this.enriched,
    this.initialTab = 0,
  });

  final CustomerEnriched enriched;
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final svc = context.read<CustomerAdminService>();
    final docId = enriched.displayId;
    final blocked = enriched.customer.isBlocked;
    final codEnabled = enriched.customer.codEnabled;

    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (action) async {
        switch (action) {
          case 'view':
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerProfileScreen(
                  enriched: enriched,
                  initialTab: initialTab,
                ),
              ),
            );
          case 'orders':
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerProfileScreen(
                  enriched: enriched,
                  initialTab: 1,
                ),
              ),
            );
          case 'cod':
            await _toggleCod(context, docId, codEnabled);
          case 'block':
            await svc.setBlocked(docId, !blocked);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(blocked ? 'User unblocked' : 'User blocked'),
                ),
              );
            }
          case 'delete':
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete customer?'),
                content: Text(
                  'Remove ${enriched.customer.name} permanently? This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (ok == true) await svc.deleteCustomer(docId);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'view', child: Text('View user')),
        const PopupMenuItem(value: 'orders', child: Text('View orders')),
        PopupMenuItem(
          value: 'cod',
          child: Text(
            codEnabled
                ? 'Disable COD'
                : 'Enable COD',
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Text(blocked ? 'Unblock' : 'Block'),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete user', style: TextStyle(color: Colors.red)),
        ),
      ],
      child: const Icon(Icons.more_vert, size: 20),
    );
  }

  Future<void> _toggleCod(
    BuildContext context,
    String userId,
    bool currentlyEnabled,
  ) async {
    final name = enriched.customer.name;
    if (currentlyEnabled) {
      final reason = await showDialog<String>(
        context: context,
        builder: (ctx) => _DisableCodDialog(userName: name),
      );
      if (reason == null || !context.mounted) return;
      try {
        await CodRestrictionAdminService().updateForUser(
          userId: userId,
          type: CodRestrictionType.permanent,
          reason: reason,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'COD disabled for $name — online payment only',
            ),
          ),
        );
      } on FirebaseFunctionsException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? e.code)),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not disable COD: $e')),
        );
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable COD?'),
        content: Text(
          'Allow cash on delivery again for ${name.isEmpty ? 'this user' : name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable COD'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await CodRestrictionAdminService().removeForUser(userId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('COD enabled for $name')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not enable COD: $e')),
      );
    }
  }
}

class _DisableCodDialog extends StatefulWidget {
  const _DisableCodDialog({required this.userName});

  final String userName;

  @override
  State<_DisableCodDialog> createState() => _DisableCodDialogState();
}

class _DisableCodDialogState extends State<_DisableCodDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Disable COD'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.userName.isEmpty
                  ? 'This user will only be able to pay online.'
                  : '${widget.userName} will only be able to pay online.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reason,
              maxLines: 2,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(),
                hintText: 'Fake orders / cancellations / fraud…',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reason.text.trim();
            if (reason.isEmpty) return;
            Navigator.pop(context, reason);
          },
          child: const Text('Disable COD'),
        ),
      ],
    );
  }
}
