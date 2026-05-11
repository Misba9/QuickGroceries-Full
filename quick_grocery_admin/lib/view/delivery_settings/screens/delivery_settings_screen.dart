import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_settings/services/delivery_settings_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';

/// **Platform Fee → Delivery Settings**
///
/// Four sections: free delivery, delivery fee, live preview, save — responsive,
/// no horizontal overflow (single column + constrained max width).
class DeliverySettingsScreen extends StatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DeliverySettingsService>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeliverySettingsService>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pad = adminResponsivePadding(w);

          return Column(
            children: [
              const PrimaryAppBar(),
              AppSpacing.h20,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pad),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 720,
                        minWidth: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Platform Fee → Delivery Settings',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Delivery Settings',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Changes sync to the customer app in realtime over Firestore.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _LiveSyncRow(lastUpdated: service.lastUpdatedAt),
                          SizedBox(height: pad),

                          // SECTION 1
                          _AdminSectionCard(
                            title: 'Free Delivery Configuration',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Enable Free Delivery',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: service.isFreeDeliveryEnabled,
                                  activeThumbColor: AppColor.primary,
                                  onChanged: service.setFreeDeliveryEnabled,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Free Delivery Threshold Amount',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller:
                                      service.freeDeliveryThresholdController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter amount',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Examples: 99 · 149 · 299',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Free Delivery Banner Preview',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _PreviewChip(
                                  text: service.freeDeliveryBannerPreview(),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: pad),

                          // SECTION 2
                          _AdminSectionCard(
                            title: 'Delivery Fee Configuration',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Enable Delivery Charges',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: service.isDeliveryChargesEnabled,
                                  activeThumbColor: AppColor.primary,
                                  onChanged: service.setDeliveryChargesEnabled,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Delivery Fee Amount',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: service.deliveryFeeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'e.g. 25',
                                    prefixText: '₹ ',
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Delivery Fee Preview',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _PreviewChip(
                                  text: service.deliveryFeePreviewSentence(),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: pad),

                          // SECTION 3 — Live preview (animates on edits)
                          _AdminSectionCard(
                            title: 'Live Preview',
                            child: _LivePreviewBody(
                              key: ValueKey(
                                '${service.isFreeDeliveryEnabled}'
                                '${service.isDeliveryChargesEnabled}'
                                '${service.parsedThreshold}'
                                '${service.parsedDeliveryFee}',
                              ),
                              service: service,
                            ),
                          ),

                          SizedBox(height: pad),

                          // SECTION 4 — Save
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: w < 420 ? double.infinity : 280,
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: service.isLoading
                                      ? null
                                      : () => service.save(context),
                                  child: service.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : Text(
                                          'Save Delivery Settings',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: pad),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LivePreviewBody extends StatelessWidget {
  const _LivePreviewBody({super.key, required this.service});

  final DeliverySettingsService service;

  @override
  Widget build(BuildContext context) {
    final t = service.parsedThreshold ?? 0;
    final f = service.parsedDeliveryFee ?? 0;
    final freeOn = service.isFreeDeliveryEnabled;
    final chargesOn = service.isDeliveryChargesEnabled;

    String aboveLine() {
      if (!chargesOn) return 'Delivery charges OFF → FREE delivery';
      if (!freeOn) return 'Free delivery promos OFF';
      return 'Orders above ₹$t → FREE delivery';
    }

    String belowLine() {
      if (!chargesOn) return 'No delivery fee on any order';
      if (!freeOn) {
        return 'Delivery fee ₹$f applies (free threshold disabled)';
      }
      return 'Orders below ₹$t → ₹$f delivery fee';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            aboveLine(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 10),
          Text(
            belowLine(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              height: 1.4,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.04, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }
}

class _LiveSyncRow extends StatelessWidget {
  const _LiveSyncRow({this.lastUpdated});

  final DateTime? lastUpdated;

  static String _formatLocal(DateTime d) {
    final l = d.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${l.year} $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = lastUpdated == null
        ? 'Live synced · load remote values to see last saved time'
        : 'Live synced · last saved ${_formatLocal(lastUpdated!)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(Icons.circle, size: 8, color: Colors.green.shade600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 4,
                color: AppColor.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      child,
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
        border: Border.all(
          color: AppColor.primary.withValues(alpha: 0.35),
        ),
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
