import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/analytics/models/analytics_snapshot.dart';
import 'package:quick_grocery_admin/view/analytics/services/analytics_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide ChartPoint;

/// Blinkit / Zepto–style analytics surface (revenue, orders, products, ops).
class AdvancedAnalyticsDashboard extends StatelessWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AnalyticsService>();
    final s = a.snapshot;
    final w = MediaQuery.sizeOf(context).width;
    final pad = adminResponsivePadding(w);
    final narrow = adminIsMobileWidth(w);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterToolbar(narrow: narrow),
        if (a.sideLoading) ...[
          AppSpacing.h10,
          const LinearProgressIndicator(minHeight: 3),
        ],
        if (a.loadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Side data: ${a.loadError}',
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        SizedBox(height: pad),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _GlassKpi(
              width: narrow ? w - pad * 2 : 200,
              title: 'Delivered revenue',
              value: '₹${NumberFormat.compact().format(s.deliveredRevenue.round())}',
              subtitle: s.rangeLabel,
              trend: '${s.revenueGrowthPercent >= 0 ? '+' : ''}${s.revenueGrowthPercent.toStringAsFixed(1)}% vs prev',
              positive: s.revenueGrowthPercent >= 0,
            ),
            _GlassKpi(
              width: narrow ? w - pad * 2 : 200,
              title: 'Orders (window)',
              value: '${s.totalOrders}',
              subtitle: '${s.deliveredOrders} delivered · ${s.cancelledOrders} cancelled',
              trend: 'Success ${s.orderSuccessRate.toStringAsFixed(0)}%',
              positive: s.orderSuccessRate >= 80,
            ),
            _GlassKpi(
              width: narrow ? w - pad * 2 : 200,
              title: 'Avg order value',
              value: s.deliveredOrders > 0
                  ? '₹${(s.deliveredRevenue / s.deliveredOrders).round()}'
                  : '—',
              subtitle: 'Delivered only',
              trend: '${s.pendingOrders} pending pipeline',
              positive: true,
            ),
            _GlassKpi(
              width: narrow ? w - pad * 2 : 200,
              title: 'Est. gross margin line',
              value: '₹${NumberFormat.compact().format(s.estimatedGrossProfit.round())}',
              subtitle: 'Revenue − discounts − refunds',
              trend: 'Vendor payouts N/A in Firestore',
              positive: s.estimatedGrossProfit >= 0,
            ),
          ],
        ),
        SizedBox(height: pad),
        LayoutBuilder(
          builder: (context, c) {
            final full = c.maxWidth;
            final half = (full - 12) / 2;
            final chartW = narrow ? full : half.clamp(280.0, 800.0);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: chartW,
                  height: 320,
                  child: _GlassPanel(
                    child: s.dailyRevenue.isEmpty
                        ? const Center(child: Text('No delivered revenue in range'))
                        : SfCartesianChart(
                            plotAreaBorderWidth: 0,
                            primaryXAxis: CategoryAxis(
                              majorGridLines: const MajorGridLines(width: 0),
                            ),
                            primaryYAxis: NumericAxis(
                              numberFormat: NumberFormat.compactCurrency(
                                symbol: '₹',
                                decimalDigits: 0,
                              ),
                            ),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries<ChartPoint, String>>[
                              SplineAreaSeries<ChartPoint, String>(
                                dataSource: s.dailyRevenue,
                                xValueMapper: (d, _) => d.label,
                                yValueMapper: (d, _) => d.value,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColor.primary.withValues(alpha: 0.45),
                                    AppColor.primary.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderColor: AppColor.primary,
                                borderWidth: 2.5,
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(
                  width: chartW,
                  height: 320,
                  child: _GlassPanel(
                    child: s.orderStatusSlices.isEmpty
                        ? const Center(child: Text('No orders in range'))
                        : SfCircularChart(
                            legend: Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CircularSeries>[
                              DoughnutSeries<MapEntry<String, double>, String>(
                                dataSource: s.orderStatusSlices.entries.toList(),
                                xValueMapper: (e, _) => e.key,
                                yValueMapper: (e, _) => e.value,
                                innerRadius: '62%',
                                explode: true,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  labelPosition: ChartDataLabelPosition.outside,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(
                  width: narrow ? full : full,
                  height: 260,
                  child: _GlassPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order intensity by hour (heatmap-style)',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(
                              title: AxisTitle(text: 'Hour (local)'),
                            ),
                            primaryYAxis: NumericAxis(
                              title: AxisTitle(text: 'Orders'),
                              decimalPlaces: 0,
                            ),
                            series: <CartesianSeries<_HourBar, String>>[
                              ColumnSeries<_HourBar, String>(
                                dataSource: List.generate(
                                  24,
                                  (h) => _HourBar('$h', s.hourlyOrderHeat[h]),
                                ),
                                xValueMapper: (d, _) => d.h,
                                yValueMapper: (d, _) => d.v,
                                pointColorMapper: (d, _) {
                                  final mx = s.hourlyOrderHeat.fold<double>(
                                    0,
                                    (a, b) => a > b ? a : b,
                                  );
                                  final t = (d.v / (mx <= 0 ? 1 : mx)).clamp(0.0, 1.0);
                                  return Color.lerp(
                                        Colors.grey.shade200,
                                        AppColor.primary,
                                        t,
                                      ) ??
                                      AppColor.primary;
                                },
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
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
        SizedBox(height: pad),
        Text(
          'Top SKUs (delivered units in range)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        AppSpacing.h10,
        _GlassPanel(
          child: s.topProducts.isEmpty
              ? Text(
                  'No delivered line-items in this range.',
                  style: GoogleFonts.poppins(fontSize: 13),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.topProducts
                      .take(10)
                      .map(
                        (p) => Chip(
                          avatar: CircleAvatar(
                            backgroundColor:
                                AppColor.primary.withValues(alpha: 0.25),
                            child: Text(
                              '${p.unitsSold}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          label: Text(
                            p.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        SizedBox(height: pad),
        Text(
          'Commerce & ops',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        AppSpacing.h10,
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoCard(
              width: narrow ? w - pad * 2 : 320,
              title: 'Products',
              lines: [
                'Top SKUs (delivered units): ${s.topProducts.take(3).map((e) => e.name).join(', ')}',
                'Low stock (≤5): ${s.lowStockSkus} · Out of stock: ${s.outOfStockSkus}',
              ],
            ),
            _InfoCard(
              width: narrow ? w - pad * 2 : 320,
              title: 'Customers',
              lines: [
                'New (profile date in range): ${s.newCustomersInRange}',
                'Returning buyers (2+ delivered): ${s.returningBuyers}',
                'Retention index: ${s.estimatedRetentionPercent.toStringAsFixed(0)}%',
              ],
            ),
            _InfoCard(
              width: narrow ? w - pad * 2 : 320,
              title: 'Delivery',
              lines: [
                if (s.avgDeliveryMinutes != null)
                  'Avg fulfil time (confirm→delivered): ${s.avgDeliveryMinutes!.round()} min'
                else
                  'Avg fulfil time: insufficient timestamps',
                'SLA breaches (>45m): ${s.delayedDeliveries}',
                'Riders with loads: ${s.deliveryBoyOrderLoads.length}',
              ],
            ),
            _InfoCard(
              width: narrow ? w - pad * 2 : 320,
              title: 'Live pulse',
              lines: [
                'Pending online payments: ${s.pendingPayments}',
                'Out for delivery: ${s.outForDelivery}',
                'Recent IDs: ${s.recentOrderIds.join(', ')}',
              ],
            ),
            _InfoCard(
              width: narrow ? w - pad * 2 : 320,
              title: 'Marketing',
              lines: [
                'Coupons in catalogue: ${s.couponDocuments}',
                'Banner views (sum): ${s.bannerViews} · clicks: ${s.bannerClicks}',
              ],
            ),
          ],
        ),
        SizedBox(height: pad),
        Row(
          children: [
            Text(
              'Top buyers (delivered revenue)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        AppSpacing.h10,
        _GlassPanel(
          child: s.topBuyers.isEmpty
              ? const Text('No buyer data in selected window')
              : Column(
                  children: s.topBuyers
                      .map(
                        (b) => ListTile(
                          dense: true,
                          title: Text(b.displayName),
                          subtitle: Text('${b.deliveredCount} delivered orders'),
                          trailing: Text(
                            '₹${b.revenue.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _HourBar {
  _HourBar(this.h, this.v);
  final String h;
  final double v;
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({required this.narrow});

  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AnalyticsService>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Range',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              ...AnalyticsDatePreset.values.where((p) => p != AnalyticsDatePreset.custom).map(
                    (p) => ChoiceChip(
                      label: Text(_label(p)),
                      selected: a.preset == p,
                      onSelected: (_) => a.setPreset(p),
                      selectedColor: AppColor.primary.withValues(alpha: 0.35),
                    ),
                  ),
              IconButton(
                tooltip: 'Copy CSV (delivered revenue)',
                icon: const Icon(Icons.table_chart_outlined),
                onPressed: () => a.exportCsvDeliveredRevenue(context),
              ),
              IconButton(
                tooltip: 'Export PDF summary',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => a.exportPdfSummary(),
              ),
              IconButton(
                tooltip: 'Refresh catalog / banners',
                icon: const Icon(Icons.refresh),
                onPressed: () => a.refreshSideData(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(AnalyticsDatePreset p) {
    switch (p) {
      case AnalyticsDatePreset.today:
        return 'Today';
      case AnalyticsDatePreset.week:
        return '7d';
      case AnalyticsDatePreset.month:
        return '30d';
      case AnalyticsDatePreset.year:
        return '365d';
      case AnalyticsDatePreset.all:
        return 'All';
      case AnalyticsDatePreset.custom:
        return 'Custom';
    }
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.72),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassKpi extends StatelessWidget {
  const _GlassKpi({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.positive,
  });

  final double width;
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.55),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, __) => Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - t)),
                      child: Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  trend,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: positive ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.width,
    required this.title,
    required this.lines,
  });

  final double width;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: _GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '· $l',
                  style: GoogleFonts.poppins(fontSize: 12.5, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
