import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/order_models.dart';

class RiderCard extends StatelessWidget {
  const RiderCard({
    super.key,
    required this.rider,
    required this.order,
    required this.onChat,
  });

  final RiderLocation? rider;
  final LiveOrder order;
  final VoidCallback onChat;

  static Future<void> launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!order.hasRider) return const _NoRiderYet();

    final r = rider;
    final name = r?.name ?? 'Your rider';
    final phone = r?.phone ?? '';

    return FadeInUp(
      duration: const Duration(milliseconds: 420),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey.shade900],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColor.primary,
                  backgroundImage: (r?.image ?? '').isNotEmpty
                      ? NetworkImage(r!.image)
                      : null,
                  child: (r?.image ?? '').isEmpty
                      ? const Icon(Icons.delivery_dining, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        phone.isEmpty ? 'On the way' : phone,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                      if ((r?.vehicleType ?? '').isNotEmpty ||
                          (r?.vehicleNumber ?? '').isNotEmpty)
                        Text(
                          [
                            if ((r?.vehicleType ?? '').isNotEmpty) r!.vehicleType,
                            if ((r?.vehicleNumber ?? '').isNotEmpty)
                              r!.vehicleNumber,
                          ].join(' · '),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                _RoundIconBtn(
                  icon: Icons.chat_bubble_outline,
                  onTap: onChat,
                ),
                const SizedBox(width: 8),
                _RoundIconBtn(
                  icon: Icons.call,
                  enabled: phone.isNotEmpty,
                  onTap: () => RiderCard.launchCall(phone),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_outline,
                    color: AppColor.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Delivery OTP — share with rider on arrival',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _OtpChip(otp: order.deliveryOtp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRiderYet extends StatelessWidget {
  const _NoRiderYet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Searching for delivery partner…',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'We\'re finding the closest rider for your order.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 28,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: enabled ? Colors.black : Colors.white54,
            size: 20),
      ),
    );
  }
}

class _OtpChip extends StatefulWidget {
  const _OtpChip({required this.otp});

  final String otp;

  @override
  State<_OtpChip> createState() => _OtpChipState();
}

class _OtpChipState extends State<_OtpChip> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final display = _revealed
        ? widget.otp
        : widget.otp.replaceAll(RegExp(r'\d'), '•');
    return InkWell(
      onTap: () => setState(() => _revealed = !_revealed),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              display,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _revealed ? Icons.visibility_off : Icons.visibility,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
