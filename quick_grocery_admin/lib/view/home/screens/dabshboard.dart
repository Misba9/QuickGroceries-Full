import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';
import 'package:quick_grocery_admin/view/operations/widgets/admin_notification_bell.dart';
import 'package:quick_grocery_admin/view/operations/widgets/ops_live_panel.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';

/// Operations dashboard — scroll provided by [AdminPageSlot] / [AdminPageWrapper].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashBoardServices>();
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final revenueToday = context.select<OpsDashboardService, double>(
      (s) => s.revenue.today,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardHeader(),
        const SizedBox(height: 20),
        _DashboardStatsGrid(
          provider: provider,
          revenueTodayLabel: currency.format(revenueToday),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminOpsTopBar(
          title: 'Operations dashboard',
          subtitle: 'Live revenue, order queue, and delivery ops',
        ),
        const OpsLivePanel(),
        const SizedBox(height: 20),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            SvgPicture.asset('assets/icons/chart.svg', width: 24, height: 24),
            Text(
              'Catalog overview',
              style: AppTextStyles.dashboardTitle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Customer, vendor, and product counts update live from Firestore.',
          style: AppTextStyles.dashboardSubtitle,
        ),
        const SizedBox(height: 12),
        Consumer<DashBoardServices>(
          builder: (context, dash, _) => AdminLiveSyncBar(
            state: dash.dashboardSyncState,
            label: 'Dashboard',
          ),
        ),
      ],
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({
    required this.provider,
    required this.revenueTodayLabel,
  });

  final DashBoardServices provider;
  final String revenueTodayLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _DashboardStatCard(
          title: 'Total Customers',
          value: provider.customers?.length.toString(),
          loading: provider.customers == null,
        ),
        _DashboardStatCard(
          title: 'Total Vendors',
          value: provider.vendors?.length.toString(),
          loading: provider.vendors == null,
        ),
        _DashboardStatCard(
          title: 'Total Orders (all)',
          value: provider.orders?.length.toString(),
          loading: provider.orders == null,
        ),
        _DashboardStatCard(
          title: 'Total Products',
          value: provider.products?.length.toString(),
          loading: provider.products == null,
        ),
        _DashboardStatCard(
          title: 'Active Products',
          value: provider.productMetrics.active.toString(),
          loading: provider.products == null,
        ),
        _DashboardStatCard(
          title: 'Out of Stock',
          value: provider.productMetrics.outOfStock.toString(),
          loading: provider.products == null,
        ),
        _DashboardStatCard(
          title: 'Low Stock (≤5)',
          value: provider.productMetrics.lowStock.toString(),
          loading: provider.products == null,
        ),
        _DashboardStatCard(
          title: 'Categories',
          value: provider.categoriesCount.toString(),
          loading: provider.products == null && provider.categoriesCount == 0,
        ),
        _DashboardStatCard(
          title: 'Revenue today (live)',
          value: revenueTodayLabel,
          loading: false,
        ),
      ],
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.loading,
  });

  final String title;
  final String? value;
  final bool loading;

  static const double _cardWidth = 220;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      child: WrapperWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
            AppSpacing.h15,
            if (loading)
              const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  color: AppColor.primary,
                  strokeWidth: 2,
                ),
              )
            else
              Text(
                value ?? '0',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.dashboardStatValue,
              ),
          ],
        ),
      ),
    );
  }
}
