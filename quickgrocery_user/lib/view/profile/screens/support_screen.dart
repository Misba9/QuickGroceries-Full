import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  final List<String> supportNumbers = ['+919493803361'];

  SupportScreen({super.key});

  void _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot make a call. Please check your device settings.',
          ),
        ),
      );
    }
  }

  void _openWhatsApp(BuildContext context, String phoneNumber) async {
    // Remove any + or spaces from phone number for WhatsApp URL
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[+\s]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot open WhatsApp. Please check if WhatsApp is installed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('support'.tr())),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'call_our_support'.tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              ...supportNumbers.asMap().entries.map((entry) {
                final index = entry.key;
                final number = entry.value;
                return Card(
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(Icons.phone, color: AppColor.primary),
                    title: Text(
                      'support_number'.tr().replaceAll(
                        '{number}',
                        '${index + 1}',
                      ),
                    ),
                    subtitle: Text(number),
                    onTap: () => _makePhoneCall(context, number),
                  ),
                );
              }).toList(),
              Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.chat, color: Colors.green),
                  title: Text('whatsapp_support'.tr()),
                  subtitle: Text('919493803361'),
                  onTap: () => _openWhatsApp(context, '919493803361'),
                ),
              ),
              Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.mail, color: AppColor.primary),
                  title: Text('support_mail'.tr()),
                  subtitle: Text('quickgrocery@gmail.com'),
                ),
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
              Text(
                'support_call_conditions'.tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              _conditionBullet('support_available'.tr()),
              _conditionBullet('call_first'.tr()),
              _conditionBullet('missed_calls'.tr()),
              _conditionBullet('non_urgent_email'.tr()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conditionBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
