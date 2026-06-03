import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/constants/vendor_branding.dart';

/// QG Vendor logo with optional title stack.
class VendorLogo extends StatelessWidget {
  const VendorLogo({
    super.key,
    this.height = 120,
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
            VendorBranding.logoAsset,
            height: height,
            width: width ?? height * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.storefront_rounded,
              size: height * 0.6,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(height: 16),
          Text(
            VendorBranding.loginTitle,
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
