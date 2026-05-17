import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/account/edit_profile_screen.dart';
import 'package:quick_grocery_delivery/features/documents/documents_screen.dart';
import 'package:quick_grocery_delivery/features/performance/performance_screen.dart';
import 'package:quick_grocery_delivery/features/settings/settings_screen.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';
import 'package:quick_grocery_delivery/support/support_contact_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverProfileService>().profile;

    return Scaffold(
      backgroundColor: GlobalVariables.background,
      appBar: AppBar(
        title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: GlobalVariables.background,
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage:
                              profile.image.isNotEmpty ? NetworkImage(profile.image) : null,
                          child: profile.image.isEmpty
                              ? Text(
                                  profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              Text(profile.phone, style: TextStyle(color: Colors.grey.shade600)),
                              Text(profile.email, style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _tile(
                  context,
                  Icons.edit_outlined,
                  'Edit profile',
                  'Name, vehicle, bank & UPI',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
                _tile(
                  context,
                  Icons.folder_open_outlined,
                  'Documents',
                  'License, Aadhaar, PAN, RC, Insurance',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                  ),
                ),
                _tile(
                  context,
                  Icons.insights_outlined,
                  'Performance',
                  'Ratings, speed & delivery stats',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PerformanceScreen()),
                  ),
                ),
                _tile(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  'Password, notifications, logout',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                _tile(
                  context,
                  Icons.support_agent_outlined,
                  'Help & Support',
                  null,
                  () => SupportContactSheet.show(context),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Vehicle'),
                        subtitle: Text(
                          profile.vehicleType.isNotEmpty
                              ? '${profile.vehicleType} · ${profile.vehicleNumber}'
                              : 'Not set',
                        ),
                        leading: const Icon(Icons.two_wheeler_outlined),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Bank / UPI'),
                        subtitle: Text(
                          profile.upiId.isNotEmpty
                              ? 'UPI: ${profile.upiId}'
                              : profile.bankAccountNumber.isNotEmpty
                                  ? 'A/C •••• ${profile.bankAccountNumber.substring(profile.bankAccountNumber.length > 4 ? profile.bankAccountNumber.length - 4 : 0)}'
                                  : 'Not set',
                        ),
                        leading: const Icon(Icons.account_balance_outlined),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: GlobalVariables.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
