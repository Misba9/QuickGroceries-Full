import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_profile_screen.dart';
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
}
