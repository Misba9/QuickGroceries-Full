import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';
import 'package:quick_grocery_admin/view/platform_fee/widgets/free_delivery_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

String _formatLocalTs(DateTime d) =>
    d.toLocal().toString().split('.').first;

/// **Platform Fee & Charges** — legacy fee fields plus free delivery controls.
/// Uses a [ListView] body so Flutter Web never clips content below the fold.
class PlatformFeeScreen extends StatefulWidget {
  const PlatformFeeScreen({super.key});

  @override
  State<PlatformFeeScreen> createState() => _PlatformFeeScreenState();
}

class _PlatformFeeScreenState extends State<PlatformFeeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlatformFeeService>(context, listen: false).fetchCharges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlatformFeeService>();

    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.h20,
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final pad = adminResponsivePadding(w);

                return ListView(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, pad + 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset('assets/icons/chart.svg'),
                                AppSpacing.w10,
                                Expanded(
                                  child: Text(
                                    'Platform Fee',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Update platform fee, handling, delivery charge, '
                              'and free delivery rules.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (p.lastUpdatedAt != null) ...[
                              const SizedBox(height: 8),
                              _LiveRow(
                                label:
                                    'Live synced · last saved ${_formatLocalTs(p.lastUpdatedAt!)}',
                              ),
                            ],
                            const SizedBox(height: 12),
                            _FirestoreStreamStatus(docId: p.platformFeeDocId),
                            SizedBox(height: pad),

                            // ── Legacy fee card (unchanged Firestore keys) ──
                            _SectionCard(
                              title: 'Platform fee & charges',
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stored on your existing bundle document as '
                                    '`amount`, `handling_charge`, and `delivery_charge`.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _LabeledField(
                                    label: 'Platform Fee (₹)',
                                    hint: 'Enter platform fee',
                                    controller: p.platformFeeController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _LabeledField(
                                    label: 'Handling Charge (₹)',
                                    hint: '0',
                                    controller: p.handlingChargeController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _LabeledField(
                                    label: 'Delivery Charge (₹)',
                                    hint: 'e.g. 25',
                                    controller: p.deliveryChargeController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Default delivery amount when the cart is below '
                                    'the free-delivery threshold (and dynamic delivery is on).',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: pad),

                            // ── Free delivery (dedicated widget — always in tree) ──
                            RepaintBoundary(
                              child: FreeDeliverySettingsCard(service: p),
                            ),

                            SizedBox(height: pad),

                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: w < 480 ? double.infinity : 240,
                                height: 48,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: p.isLoading
                                      ? null
                                      : () => p.updateCharges(context),
                                  child: p.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.black87,
                                          ),
                                        )
                                      : Text(
                                          'Update Fee',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FirestoreStreamStatus extends StatelessWidget {
  const _FirestoreStreamStatus({required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('delivery_charge')
          .doc(docId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Connecting realtime listener…',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          );
        }
        if (snap.hasError) {
          return Text(
            'Realtime: ${snap.error}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red.shade800,
            ),
          );
        }
        final data = snap.data?.data();
        String subtitle = 'Realtime: listening to delivery_charge/$docId';
        final raw = data?['updatedAt'];
        if (raw is Timestamp) {
          subtitle =
              'Realtime: last remote write ${_formatLocalTs(raw.toDate())}';
        }
        return _LiveRow(label: subtitle);
      },
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
            label,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

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
              Container(width: 4, color: AppColor.primary),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
