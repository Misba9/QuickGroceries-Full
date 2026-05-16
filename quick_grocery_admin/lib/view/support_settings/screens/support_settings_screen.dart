import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/support_settings_defaults.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/support_settings/services/support_settings_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';

/// **Settings → Support Settings** — contact details for all apps.
class SupportSettingsScreen extends StatefulWidget {
  const SupportSettingsScreen({super.key});

  @override
  State<SupportSettingsScreen> createState() => _SupportSettingsScreenState();
}

class _SupportSettingsScreenState extends State<SupportSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SupportSettingsService>().ensureDocument();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupportSettingsService>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = adminResponsivePadding(constraints.maxWidth);

          return Column(
            children: [
              const PrimaryAppBar(),
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
                                  'Settings → Support Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Support Settings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Phone, email, and WhatsApp sync to the user, '
                                  'driver, and vendor apps in realtime.',
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
                                if (service.validationError != null) ...[
                                  const SizedBox(height: 12),
                                  _ErrorBanner(text: service.validationError!),
                                ],
                                SizedBox(height: pad),
                                _SectionCard(
                                  title: 'Contact details',
                                  child: Column(
                                    children: [
                                      _Field(
                                        label: 'Support Phone Number *',
                                        controller: service.phoneController,
                                        keyboard: TextInputType.phone,
                                        hint: SupportSettingsDefaults.phone,
                                      ),
                                      _Field(
                                        label: 'Support Email *',
                                        controller: service.emailController,
                                        keyboard: TextInputType.emailAddress,
                                        hint: SupportSettingsDefaults.email,
                                      ),
                                      _Field(
                                        label: 'WhatsApp Number (optional)',
                                        controller: service.whatsappController,
                                        keyboard: TextInputType.phone,
                                        hint: SupportSettingsDefaults.whatsapp,
                                      ),
                                      _Field(
                                        label: 'Support Message (optional)',
                                        controller: service.messageController,
                                        maxLines: 3,
                                        hint: SupportSettingsDefaults.message,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                FilledButton(
                                  onPressed: service.saving
                                      ? null
                                      : () async {
                                          final ok = await service.save();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Support settings saved'
                                                    : service.validationError ??
                                                        'Could not save',
                                              ),
                                              backgroundColor: ok
                                                  ? Colors.green.shade700
                                                  : null,
                                            ),
                                          );
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: service.saving
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Save',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
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
    ).animate().fadeIn(duration: 220.ms);
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final String? hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: Colors.red.shade800,
          ),
        ),
      ),
    );
  }
}
