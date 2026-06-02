import 'package:flutter/material.dart';

/// Rider confirmation before marking an order delivered (no OTP).
Future<bool> showConfirmDeliveryDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Mark as Delivered'),
      content: const Text(
        'Are you sure this order has been delivered?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm Delivery'),
        ),
      ],
    ),
  );
  return result == true;
}
