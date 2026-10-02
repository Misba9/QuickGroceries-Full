import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/order_models.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

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
        child: Row(
          children: [
            ClipOval(
              child: (r?.image ?? '').isNotEmpty
                  ? CachedImage(
                      url: r!.image,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      memCacheWidth: 88,
                    )
                  : ColoredBox(
                      color: AppColor.primary,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.delivery_dining, color: Colors.black),
                      ),
                    ),
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
      ),
    );
  }
}

class _NoRiderYet extends StatelessWidget {
  const _NoRiderYet();

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surface.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36, height: 36, child: AppLoading.micro),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Searching for delivery partner…',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: surface.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We\'re finding the closest rider for your order.',
                  style: TextStyle(color: surface.textMuted, fontSize: 12),
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
