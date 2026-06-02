import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Phone, WhatsApp, maps, and clipboard helpers for rider delivery screens.
class DeliveryContactUtils {
  DeliveryContactUtils._();

  static const whatsAppGreeting =
      'Hello, I am your Quick Groceries delivery partner.\n'
      'I am arriving with your order.';

  static String? normalizeDialable(String? raw) {
    if (raw == null) return null;
    var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('+')) return digits;
    if (digits.length == 10) return '+91$digits';
    return digits;
  }

  /// Digits only with country code for wa.me (no +).
  static String? normalizeWhatsApp(String? raw) {
    final dial = normalizeDialable(raw);
    if (dial == null) return null;
    return dial.replaceAll(RegExp(r'\D'), '');
  }

  static Future<void> callPhone(
    BuildContext context,
    String? phone, {
    String unavailableMessage = 'Customer phone number unavailable',
  }) async {
    final normalized = normalizeDialable(phone);
    if (normalized == null) {
      _snack(context, unavailableMessage);
      return;
    }
    final uri = Uri(scheme: 'tel', path: normalized);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        _snack(context, 'Could not open phone dialer');
      }
    }
  }

  static Future<void> openWhatsApp(
    BuildContext context,
    String? phone, {
    String message = whatsAppGreeting,
  }) async {
    final wa = normalizeWhatsApp(phone);
    if (wa == null) {
      _snack(context, 'Customer phone number unavailable');
      return;
    }
    final uri = Uri.parse(
      'https://wa.me/$wa?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        _snack(context, 'Could not open WhatsApp');
      }
    }
  }

  static Future<void> copyText(
    BuildContext context,
    String? text, {
    required String successLabel,
  }) async {
    final value = text?.trim() ?? '';
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      _snack(context, '$successLabel copied');
    }
  }

  static void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
