import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/delivery_branding.dart';

/// QG Delivery logo with optional title stack.
class DeliveryLogo extends StatelessWidget {
  const DeliveryLogo({
    super.key,
    this.height = 130,
    this.width,
    this.showTitle = true,
    this.titleStyle,
    this.subtitle,
  });

  final double height;
  final double? width;
  final bool showTitle;
  final TextStyle? titleStyle;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            DeliveryBranding.logoAsset,
            height: height,
            width: width ?? height * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.delivery_dining_rounded,
              size: height * 0.6,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          Text(
            DeliveryBranding.loginTitle,
            style: titleStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}
