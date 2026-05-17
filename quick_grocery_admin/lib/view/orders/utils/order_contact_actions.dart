import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderContactActions {
  OrderContactActions._();

  static Future<void> callCustomer(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _snack(context, 'No phone number');
      return;
    }
    final uri = Uri.parse('tel:$digits');
    if (!await launchUrl(uri)) {
      _snack(context, 'Could not open dialer');
    }
  }

  static Future<void> whatsAppCustomer(
    BuildContext context,
    String phone, {
    String? message,
  }) async {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '91$digits';
    if (digits.isEmpty) {
      _snack(context, 'No phone number');
      return;
    }
    final text = Uri.encodeComponent(
      message ?? 'Hi, this is Quick Grocery regarding your order.',
    );
    final uri = Uri.parse('https://wa.me/$digits?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack(context, 'Could not open WhatsApp');
    }
  }

  static Future<void> trackOrder(BuildContext context, double lat, double lng) async {
    if (lat == 0 && lng == 0) {
      _snack(context, 'Location not available for this order');
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _snack(context, 'Could not open maps');
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
