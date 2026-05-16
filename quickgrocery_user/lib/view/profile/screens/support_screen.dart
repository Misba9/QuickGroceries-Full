import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/support/models/support_settings_config.dart';
import 'package:quickgrocery/view/support/presentation/providers/support_settings_providers.dart';
import 'package:quickgrocery/view/support/services/support_action_launcher.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(supportSettingsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text('support'.tr())),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _SupportBody(settings: SupportSettingsConfig.defaults),
        data: (settings) => _SupportBody(settings: settings),
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  const _SupportBody({required this.settings});

  final SupportSettingsConfig settings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'call_our_support'.tr(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (settings.hasPhone)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.phone, color: AppColor.primary),
                  title: Text('support_number'.tr().replaceAll('{number}', '1')),
                  subtitle: Text(settings.phone),
                  onTap: () =>
                      SupportActionLauncher.callPhone(context, settings.phone),
                ),
              ),
            if (settings.hasWhatsapp || settings.hasPhone)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: Text('whatsapp_support'.tr()),
                  subtitle: Text(settings.whatsappLaunch),
                  onTap: () => SupportActionLauncher.openWhatsApp(
                    context,
                    settings.whatsappLaunch,
                  ),
                ),
              ),
            if (settings.hasEmail)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.mail, color: AppColor.primary),
                  title: Text('support_mail'.tr()),
                  subtitle: Text(settings.email),
                  onTap: () =>
                      SupportActionLauncher.sendEmail(context, settings.email),
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'support_call_conditions'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (settings.hasMessage)
              _conditionBullet(settings.message)
            else
              _conditionBullet('support_available'.tr()),
            _conditionBullet('call_first'.tr()),
            _conditionBullet('missed_calls'.tr()),
            _conditionBullet('non_urgent_email'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _conditionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
