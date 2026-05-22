import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
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
  void initState() {
    super.initState();
    final d = Provider.of<DashBoardServices>(context, listen: false);
    d.getCustomers();
    d.getVendors();
    d.getOrders();
    d.getProducts();
    d.fetchRevenueData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashBoardServices>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DashboardHeader(),
        const SizedBox(height: 20),
        _DashboardStatsGrid(provider: provider),
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
          subtitle: 'Live updates — no refresh needed',
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
              'Operations & analytics',
              style: AppTextStyles.dashboardTitle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Realtime order stream, delivered revenue, and catalog health.',
          style: AppTextStyles.dashboardSubtitle,
        ),
      ],
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({required this.provider});

  final DashBoardServices provider;

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
          title: 'Legacy delivered sum',
          value: '₹${provider.totalRevenue}',
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
