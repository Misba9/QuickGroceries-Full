import 'package:flutter/material.dart';

import '../data/support_settings_repository.dart';
import '../models/support_settings.dart';
import '../services/support_launcher.dart';

/// Live support contact dialog — reads `support_settings/main`.
class SupportContactDialog extends StatelessWidget {
  const SupportContactDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SupportContactDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SupportSettings>(
      stream: SupportSettingsRepository().watch(),
      builder: (context, snap) {
        final settings = snap.data ?? SupportSettings.defaults;
        final loading = snap.connectionState == ConnectionState.waiting &&
            !snap.hasData;

        return AlertDialog(
          title: const Text('Support'),
          content: loading
              ? const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need help? Contact our support team:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (settings.hasEmail)
                        _ContactRow(
                          icon: Icons.email,
                          label: settings.email,
                          onTap: () {
                            Navigator.pop(context);
                            SupportLauncher.sendEmail(context, settings.email);
                          },
                        ),
                      if (settings.hasPhone) ...[
                        const SizedBox(height: 8),
                        _ContactRow(
                          icon: Icons.phone,
                          label: settings.phone,
                          onTap: () {
                            Navigator.pop(context);
                            SupportLauncher.callPhone(context, settings.phone);
                          },
                        ),
                      ],
                      if (settings.hasWhatsapp || settings.hasPhone) ...[
                        const SizedBox(height: 8),
                        _ContactRow(
                          icon: Icons.chat,
                          label: 'WhatsApp: ${settings.whatsappLaunch}',
                          onTap: () {
                            Navigator.pop(context);
                            SupportLauncher.openWhatsApp(
                              context,
                              settings.whatsappLaunch,
                            );
                          },
                        ),
                      ],
                      if (settings.hasMessage) ...[
                        const SizedBox(height: 16),
                        Text(
                          settings.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
