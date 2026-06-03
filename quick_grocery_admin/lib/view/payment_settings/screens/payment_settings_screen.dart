import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/payment_settings/services/payment_settings_service.dart';
/// **Settings → Payment Settings** — merchant UPI & COD collection for riders.
class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentSettingsService>().ensureDocument();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PaymentSettingsService>();

    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = adminResponsivePadding(constraints.maxWidth);

          return Column(
            children: [
              AppSpacing.h20,
              Expanded(
                child: service.loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(pad),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Settings → Payment Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Payment Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Saved to Firestore at app_settings/payment. '
                                  'Delivery partners use this for UPI QR and COD collection.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                                if (service.error != null) ...[
                                  const SizedBox(height: 12),
                                  _ErrorBanner(text: service.error!),
                                ],
                                SizedBox(height: pad),
                                _SectionCard(
                                  title: 'Merchant details',
                                  child: Column(
                                    children: [
                                      _Field(
                                        label: 'Merchant Name',
                                        controller: service.merchantNameController,
                                        hint: 'Quick Groceries',
                                      ),
                                      _Field(
                                        label: 'Merchant UPI ID *',
                                        controller: service.merchantUpiController,
                                        hint: 'quickgroceries@paytm',
                                      ),
                                      Text(
                                        'Examples: quickgroceries@ybl · quickgroceries@ibl · quickgroceries@paytm',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _Field(
                                        label: 'Merchant Mobile Number',
                                        controller:
                                            service.merchantMobileController,
                                        keyboard: TextInputType.phone,
                                        hint: '+91 98765 43210',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'Collection options',
                                  child: Column(
                                    children: [
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Enable UPI Collection'),
                                        subtitle: const Text(
                                          'Show dynamic QR on Collect Payment screen',
                                        ),
                                        value: service.enableUpi,
                                        activeThumbColor: AppColor.primary,
                                        onChanged: service.setEnableUpi,
                                      ),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text('Enable COD Collection'),
                                        subtitle: const Text(
                                          'Allow cash collection by delivery partners',
                                        ),
                                        value: service.enableCod,
                                        activeThumbColor: AppColor.primary,
                                        onChanged: service.setEnableCod,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: service.saving
                                        ? null
                                        : () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final ok = await service.save();
                                            if (!mounted) return;
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Payment settings saved'
                                                      : 'Could not save settings',
                                                ),
                                                backgroundColor: ok
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            );
                                          },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColor.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: service.saving
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Save payment settings',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.red.shade800),
        ),
      ),
    );
  }
}
