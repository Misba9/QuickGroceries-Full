import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/orders/services/order_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class OrdersChartsSection extends StatelessWidget {
  const OrdersChartsSection({
    super.key,
    required this.ordersTrend,
    required this.revenueTrend,
    required this.peakHours,
  });

  final List<OrderChartPoint> ordersTrend;
  final List<OrderChartPoint> revenueTrend;
  final List<OrderChartPoint> peakHours;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        final chartW = narrow ? c.maxWidth : (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ChartPanel(
              width: chartW,
              title: 'Orders trend (7 days)',
              child: _lineChart(ordersTrend, AppColor.primary),
            ),
            _ChartPanel(
              width: chartW,
              title: 'Revenue trend (7 days)',
              child: _lineChart(
                revenueTrend,
                const Color(0xFF2563EB),
                isCurrency: true,
              ),
            ),
            _ChartPanel(
              width: narrow ? c.maxWidth : c.maxWidth,
              height: 240,
              title: 'Peak order times (today)',
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelRotation: narrow ? 45 : 0,
                ),
                primaryYAxis: NumericAxis(
                  decimalPlaces: 0,
                  majorGridLines: MajorGridLines(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries<OrderChartPoint, String>>[
                  ColumnSeries<OrderChartPoint, String>(
                    dataSource: peakHours,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    color: AppColor.primary.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
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
      return const Center(child: Text('No data yet'));
    }
    return SfCartesianChart(
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
          dataSource: data,
          xValueMapper: (d, _) => d.label,
          yValueMapper: (d, _) => d.value,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.4),
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

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.width,
    required this.title,
    required this.child,
    this.height = 260,
  });

  final double width;
  final String title;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
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
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
