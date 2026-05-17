import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/analytics/screens/advanced_analytics_dashboard.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_notification_bell.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_live_panel.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Home dashboard — legacy snapshot cards + advanced quick-commerce analytics.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Widget _dashStatCard({
    required double width,
    required String title,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      child: WrapperWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
            AppSpacing.h15,
            child,
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    final d = Provider.of<DashBoardServices>(context, listen: false);
    d.getCustomers();
    d.getVendors();
    d.getOrders();
    d.getProducts();
    d.fetchRevenueData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashBoardServices>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = adminResponsivePadding(constraints.maxWidth);
        final narrow = adminIsMobileWidth(constraints.maxWidth);
        final contentWidth =
            (constraints.maxWidth - pad * 2).clamp(0.0, 10000.0);
        final cardW3 = narrow ? contentWidth : (contentWidth - 24) / 3;
        final cardW2 = narrow ? contentWidth : (contentWidth - 12) / 2;

        return SingleChildScrollView(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminOpsTopBar(
                title: 'Operations dashboard',
                subtitle: 'Live updates — no refresh needed',
              ),
              const OpsLivePanel(),
              AppSpacing.h20,
              Row(
                children: [
                  SvgPicture.asset('assets/icons/chart.svg'),
                  AppSpacing.w10,
                  Expanded(
                    child: Text(
                      'Operations & analytics',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Realtime order stream, delivered revenue, and catalog health — '
                'Blinkit / Zepto–style control tower.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              AppSpacing.h15,
              SizedBox(
                width: contentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _dashStatCard(
                          width: cardW3,
                          title: 'Total Customers',
                          child: provider.customers == null
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(
                                    color: AppColor.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  provider.customers!.length.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                        _dashStatCard(
                          width: cardW3,
                          title: 'Total Vendors',
                          child: provider.vendors == null
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(
                                    color: AppColor.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  provider.vendors!.length.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                        _dashStatCard(
                          width: cardW3,
                          title: 'Total Orders (all)',
                          child: provider.orders == null
                              ? const SizedBox(
                                  height: 28,
                                  width: 28,
                                  child: CircularProgressIndicator(
                                    color: AppColor.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  provider.orders!.length.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardW2,
                          child: WrapperWidget(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Products',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primary,
                                  ),
                                ),
                                AppSpacing.h15,
                                provider.products == null
                                    ? const SizedBox(
                                        height: 28,
                                        width: 28,
                                        child: CircularProgressIndicator(
                                          color: AppColor.primary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        provider.products!.length.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: cardW2,
                          child: WrapperWidget(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Legacy delivered sum',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.primary,
                                  ),
                                ),
                                AppSpacing.h15,
                                Text(
                                  "₹${provider.totalRevenue}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppSpacing.h20,
              const AdvancedAnalyticsDashboard(),
            ],
          ),
        );
      },
    );
  }
}
