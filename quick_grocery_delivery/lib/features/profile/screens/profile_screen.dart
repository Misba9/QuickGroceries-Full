import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: GlobalVariables.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.support_agent_rounded,
                  color: GlobalVariables.primary,
                ),
                title: const Text(
                  'Help & Support',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Call, email, or chat on WhatsApp'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => SupportContactSheet.show(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
