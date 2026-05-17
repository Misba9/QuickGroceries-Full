import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/app_content_defaults.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/app_content_management/services/app_content_management_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';

/// **Settings → App Content** — homepage headings, greeting, delivery ETA.
class AppContentManagementScreen extends StatefulWidget {
  const AppContentManagementScreen({super.key});

  @override
  State<AppContentManagementScreen> createState() =>
      _AppContentManagementScreenState();
}

class _AppContentManagementScreenState extends State<AppContentManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppContentManagementService>().ensureDocument();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppContentManagementService>();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final pad = adminResponsivePadding(w);

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
                                  'Settings → App Content',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'App Content',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customize homepage headings, greeting, and delivery time. '
                                  'Changes appear instantly in the customer app.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _LiveSyncRow(lastUpdated: service.content.updatedAt),
                                if (service.error != null) ...[
                                  const SizedBox(height: 12),
                                  Material(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        service.error!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          color: Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: pad),
                                _AdminSectionCard(
                                  title: 'Homepage copy',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _ContentField(
                                        label: 'Home Greeting',
                                        controller: service.homeGreetingController,
                                        presets: const [
                                          'Good Morning',
                                          'Welcome Back',
                                          'Hello',
                                          'Fresh Grocery Delivered',
                                          'Good Evening',
                                        ],
                                      ),
                                      _ContentField(
                                        label: 'Trending Categories Heading',
                                        controller:
                                            service.trendingHeadingController,
                                        presets: const [
                                          'Trending categories',
                                          'Popular Categories',
                                          'Top Picks',
                                          'Trending Now',
                                          'Fresh Picks',
                                        ],
                                      ),
                                      _ContentField(
                                        label: 'Shop Category Heading',
                                        controller:
                                            service.shopCategoryHeadingController,
                                        presets: const [
                                          'Shop By Category',
                                          'Browse Categories',
                                          'Grocery Categories',
                                          'Shop Essentials',
                                          'Explore Products',
                                        ],
                                      ),
                                      _ContentField(
                                        label: 'Flash Deal Heading',
                                        controller:
                                            service.flashDealHeadingController,
                                        presets: const [
                                          'Flash deals',
                                          'Hot Deals',
                                          'Limited Offers',
                                          'Mega Discounts',
                                          'Daily Offers',
                                        ],
                                      ),
                                      _ContentField(
                                        label: 'Delivery Time Text',
                                        controller:
                                            service.deliveryTimeTextController,
                                        presets: const [
                                          'Delivery in 10 mins',
                                          'Delivery in 15 mins',
                                          'Delivery in 30 mins',
                                          'Express Delivery',
                                          'Scheduled Delivery',
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AdminSectionCard(
                                  title: 'Section visibility',
                                  child: Column(
                                    children: [
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Show trending categories',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        value: service.content.showTrendingCategories,
                                        activeThumbColor: AppColor.primary,
                                        onChanged: service.setShowTrendingCategories,
                                      ),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Show shop by category',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        value: service.content.showShopCategory,
                                        activeThumbColor: AppColor.primary,
                                        onChanged: service.setShowShopCategory,
                                      ),
                                      SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          'Show flash deals',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        value: service.content.showFlashDeals,
                                        activeThumbColor: AppColor.primary,
                                        onChanged: service.setShowFlashDeals,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _AdminSectionCard(
                                  title: 'Live preview',
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _PreviewChip(
                                        label: 'Greeting',
                                        text: service.homeGreetingController.text
                                            .trim()
                                            .isEmpty
                                            ? AppContentDefaults.homeGreeting
                                            : service.homeGreetingController.text,
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewChip(
                                        label: 'Delivery',
                                        text: service.deliveryTimeTextController.text
                                            .trim()
                                            .isEmpty
                                            ? AppContentDefaults.deliveryTimeText
                                            : service.deliveryTimeTextController.text,
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewChip(
                                        label: 'Trending',
                                        text: service.trendingHeadingController.text
                                            .trim()
                                            .isEmpty
                                            ? AppContentDefaults.trendingHeading
                                            : service.trendingHeadingController.text,
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewChip(
                                        label: 'Shop',
                                        text: service.shopCategoryHeadingController.text
                                            .trim()
                                            .isEmpty
                                            ? AppContentDefaults.shopCategoryHeading
                                            : service.shopCategoryHeadingController.text,
                                      ),
                                      const SizedBox(height: 8),
                                      _PreviewChip(
                                        label: 'Flash deals',
                                        text: service.flashDealHeadingController.text
                                            .trim()
                                            .isEmpty
                                            ? AppContentDefaults.flashDealHeading
                                            : service.flashDealHeadingController.text,
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
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'App content saved — live in customer app'
                                                    : 'Could not save. Try again.',
                                              ),
                                              backgroundColor:
                                                  ok ? Colors.green.shade700 : null,
                                            ),
                                          );
                                        },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColor.primary,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                                          'Save changes',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: service.saving
                                      ? null
                                      : () async {
                                          service.homeGreetingController.text =
                                              AppContentDefaults.homeGreeting;
                                          service.trendingHeadingController.text =
                                              AppContentDefaults.trendingHeading;
                                          service.shopCategoryHeadingController.text =
                                              AppContentDefaults.shopCategoryHeading;
                                          service.flashDealHeadingController.text =
                                              AppContentDefaults.flashDealHeading;
                                          service.deliveryTimeTextController.text =
                                              AppContentDefaults.deliveryTimeText;
                                          service.setShowTrendingCategories(true);
                                          service.setShowShopCategory(true);
                                          service.setShowFlashDeals(true);
                                          final ok = await service.save();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                ok
                                                    ? 'Reset to defaults'
                                                    : 'Reset failed',
                                              ),
                                            ),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    'Reset to defaults',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
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

class _ContentField extends StatelessWidget {
  const _ContentField({
    required this.label,
    required this.controller,
    required this.presets,
  });

  final String label;
  final TextEditingController controller;
  final List<String> presets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
            maxLines: 1,
            decoration: InputDecoration(
              hintText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presets.map((preset) {
              return ActionChip(
                label: Text(
                  preset,
                  style: GoogleFonts.poppins(fontSize: 11.5),
                ),
                onPressed: () {
                  controller.text = preset;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
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
        ? 'Live synced · save once to stamp updated time'
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
  const _PreviewChip({required this.label, required this.text});

  final String label;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
