import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/core/widgets/safe_syncfusion_chart.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class OrdersChartsSection extends StatelessWidget {
  const OrdersChartsSection({
    super.key,
    required this.ordersTrend,
    required this.revenueTrend,
  });

  final List<OrderChartPoint> ordersTrend;
  final List<OrderChartPoint> revenueTrend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 900;
        final gap = 20.0;
        final chartW = narrow ? c.maxWidth : (c.maxWidth - gap) / 2;

        final ordersChart = _ChartCard(
          width: chartW,
          title: 'Orders trend',
          subtitle: 'Last 7 days',
          child: _lineChart(ordersTrend, AppColor.primary),
        );
        final revenueChart = _ChartCard(
          width: chartW,
          title: 'Revenue trend',
          subtitle: 'Last 7 days',
          child: _lineChart(
            revenueTrend,
            const Color(0xFF2563EB),
            isCurrency: true,
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ordersChart,
              SizedBox(height: gap),
              revenueChart,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ordersChart,
            SizedBox(width: gap),
            revenueChart,
          ],
        );
      },
    );
  }

  Widget _lineChart(
    List<OrderChartPoint> data,
    Color color, {
    bool isCurrency = false,
  }) {
    if (data.every((e) => e.value == 0)) {
      return const Center(
        child: Text('No data yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return SafeSfCartesianChart(
      height: 260,
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(majorGridLines: const MajorGridLines(width: 0)),
      primaryYAxis: NumericAxis(
        numberFormat: isCurrency
            ? NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 0)
            : null,
        majorGridLines: MajorGridLines(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<OrderChartPoint, String>>[
        SplineAreaSeries<OrderChartPoint, String>(
          animationDuration: 0,
          dataSource: data,
          xValueMapper: (d, _) => d.label,
          yValueMapper: (d, _) => d.value,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.35),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: color,
          borderWidth: 2.5,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}
