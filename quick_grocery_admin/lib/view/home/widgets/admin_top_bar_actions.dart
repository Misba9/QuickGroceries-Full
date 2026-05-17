import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_notification_bell.dart';

/// Notification + logout actions shown on every admin screen.
class AdminTopBarActions extends StatelessWidget {
  const AdminTopBarActions({super.key});

  static Future<void> confirmAndSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to access the admin panel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AdminNotificationBell(),
        IconButton(
          tooltip: 'Log out',
          onPressed: () => confirmAndSignOut(context),
          icon: Icon(
            Icons.logout_rounded,
            color: Colors.red.shade700,
          ),
        ),
      ],
    );
  }
}
