import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';

/// Free-delivery toggles, threshold, and live copy preview — used on
/// [PlatformFeeScreen] below the legacy fee fields.
class FreeDeliverySettingsCard extends StatefulWidget {
  const FreeDeliverySettingsCard({super.key, required this.service});

  final PlatformFeeService service;

  @override
  State<FreeDeliverySettingsCard> createState() =>
      _FreeDeliverySettingsCardState();
}

class _FreeDeliverySettingsCardState extends State<FreeDeliverySettingsCard> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[FreeDeliverySettingsCard] widget loaded');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.service;

    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 4, color: AppColor.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free Delivery Settings',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable Free Delivery',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: p.freeDeliveryEnabled,
                        activeThumbColor: AppColor.primary,
                        onChanged: p.setFreeDeliveryEnabled,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Free Delivery Threshold Amount (₹)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: p.freeDeliveryThresholdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '99 · 149 · 299',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Enable Dynamic Delivery Fee',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'When off, delivery fee is waived. When on, carts below '
                          'the threshold use your delivery charge.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        value: p.dynamicDeliveryEnabled,
                        activeThumbColor: AppColor.primary,
                        onChanged: p.setDynamicDeliveryEnabled,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Live Preview',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviewChip(text: p.freeDeliveryBannerPreview()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          height: 1.35,
        ),
      ),
    );
  }
}
