import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

import 'support_launcher.dart';
import 'support_settings.dart';
import 'support_settings_repository.dart';

/// Bottom sheet with live support contact from Firestore.
class SupportContactSheet extends StatelessWidget {
  const SupportContactSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SupportContactSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SupportSettings>(
      stream: SupportSettingsRepository().watch(),
      builder: (context, snap) {
        final settings = snap.data ?? SupportSettings.defaults;
        final loading =
            snap.connectionState == ConnectionState.waiting && !snap.hasData;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: loading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GlobalVariables.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (settings.hasPhone)
                      _Tile(
                        icon: Icons.phone,
                        title: 'Call',
                        subtitle: settings.phone,
                        onTap: () {
                          Navigator.pop(context);
                          SupportLauncher.callPhone(context, settings.phone);
                        },
                      ),
                    if (settings.hasEmail)
                      _Tile(
                        icon: Icons.email,
                        title: 'Email',
                        subtitle: settings.email,
                        onTap: () {
                          Navigator.pop(context);
                          SupportLauncher.sendEmail(context, settings.email);
                        },
                      ),
                    if (settings.hasWhatsapp || settings.hasPhone)
                      _Tile(
                        icon: Icons.chat,
                        title: 'WhatsApp',
                        subtitle: settings.whatsappLaunch,
                        onTap: () {
                          Navigator.pop(context);
                          SupportLauncher.openWhatsApp(
                            context,
                            settings.whatsappLaunch,
                          );
                        },
                      ),
                    if (settings.hasMessage) ...[
                      const SizedBox(height: 12),
                      Text(
                        settings.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: GlobalVariables.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
