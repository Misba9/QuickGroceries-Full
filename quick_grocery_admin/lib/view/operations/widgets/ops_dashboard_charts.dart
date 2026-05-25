import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/widgets/safe_syncfusion_chart.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/services/ops_dashboard_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class OpsDashboardCharts extends StatelessWidget {
  const OpsDashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    final rev = context.select<OpsDashboardService, OpsRevenueSnapshot>((s) => s.revenue);

    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 960;
        final gap = 16.0;
        final chartW = narrow ? c.maxWidth : (c.maxWidth - gap) / 2;

        final children = <Widget>[
          _ChartCard(
            width: chartW,
            title: 'Revenue trend',
            subtitle: 'Delivered · last 7 days',
            child: _areaChart(rev.revenueTrend7d, const Color(0xFF2563EB), currency: true),
          ),
          _ChartCard(
            width: chartW,
            title: 'Orders trend',
            subtitle: 'Placed · last 7 days',
            child: _areaChart(rev.ordersTrend7d, AppColor.primary),
          ),
          _ChartCard(
            width: chartW,
            title: 'Delivery heatmap',
            subtitle: 'Deliveries today by hour',
            child: _columnChart(rev.deliveryHeatmapToday, const Color(0xFF047857)),
          ),
          _ChartCard(
            width: chartW,
            title: 'Vendor activity',
            subtitle: 'Orders today by vendor',
            child: _columnChart(rev.vendorActivityToday, const Color(0xFF6D28D9)),
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                children[0],
                SizedBox(width: gap),
                children[1],
              ],
            ),
            SizedBox(height: gap),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                children[2],
                SizedBox(width: gap),
                children[3],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _areaChart(
    List<OpsChartPoint> data,
    Color color, {
    bool currency = false,
  }) {
    if (data.every((e) => e.value == 0)) {
      return const _EmptyChart();
    }
    final fmt = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');
    return SafeSfCartesianChart(
      height: 220,
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        labelStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(color: Colors.grey.shade200),
        numberFormat: currency ? fmt : null,
      ),
      series: <CartesianSeries<OpsChartPoint, String>>[
        SplineAreaSeries<OpsChartPoint, String>(
          dataSource: data,
          xValueMapper: (p, _) => p.label,
          yValueMapper: (p, _) => p.value,
          color: color.withValues(alpha: 0.25),
          borderColor: color,
          borderWidth: 2,
        ),
      ],
    );
  }

  Widget _columnChart(List<OpsChartPoint> data, Color color) {
    if (data.isEmpty || data.every((e) => e.value == 0)) {
      return const _EmptyChart();
    }
    return SafeSfCartesianChart(
      height: 220,
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        labelStyle: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(color: Colors.grey.shade200),
      ),
      series: <CartesianSeries<OpsChartPoint, String>>[
        ColumnSeries<OpsChartPoint, String>(
          dataSource: data,
          xValueMapper: (p, _) => p.label,
          yValueMapper: (p, _) => p.value,
          color: color.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final double width;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Text('No data yet', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
