import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportLauncher {
  static Future<void> callPhone(BuildContext context, String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (normalized.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      _snack(context, 'Cannot open the phone dialer.');
    }
  }

  static Future<void> sendEmail(BuildContext context, String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri(scheme: 'mailto', path: trimmed);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      _snack(context, 'Cannot open the mail app.');
    }
  }

  static Future<void> openWhatsApp(BuildContext context, String number) async {
    final clean = number.replaceAll(RegExp(r'[+\s\-()]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _snack(context, 'Cannot open WhatsApp.');
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
