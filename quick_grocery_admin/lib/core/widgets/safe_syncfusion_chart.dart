import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Wraps [SfCartesianChart] with fixed size, no axis animation, and safe disposal.
class SafeSfCartesianChart extends StatefulWidget {
  const SafeSfCartesianChart({
    super.key,
    required this.series,
    this.height = 260,
    this.width,
    this.title,
    this.primaryXAxis,
    this.primaryYAxis,
    this.legend,
    this.tooltipBehavior,
    this.backgroundColor,
    this.plotAreaBorderWidth = 0,
    this.dataKey,
  });

  final List<CartesianSeries<dynamic, dynamic>> series;
  final double height;
  final double? width;
  final ChartTitle? title;
  final ChartAxis? primaryXAxis;
  final ChartAxis? primaryYAxis;
  final Legend? legend;
  final TooltipBehavior? tooltipBehavior;
  final Color? backgroundColor;
  final double plotAreaBorderWidth;

  /// When set, forces a new chart instance when data identity changes.
  final Object? dataKey;

  @override
  State<SafeSfCartesianChart> createState() => _SafeSfCartesianChartState();
}

class _SafeSfCartesianChartState extends State<SafeSfCartesianChart> {
  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return SizedBox(height: widget.height, width: widget.width);
    }

    if (widget.series.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(child: Text('No chart data')),
      );
    }

    final chartKey = widget.dataKey ?? widget.series.length;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: SfCartesianChart(
          key: ValueKey<Object>(chartKey),
          enableAxisAnimation: false,
          backgroundColor: widget.backgroundColor,
          title: widget.title ?? const ChartTitle(text: ''),
          legend: widget.legend ?? const Legend(isVisible: false),
          tooltipBehavior: widget.tooltipBehavior,
          plotAreaBorderWidth: widget.plotAreaBorderWidth,
          primaryXAxis: widget.primaryXAxis ?? const CategoryAxis(),
          primaryYAxis: widget.primaryYAxis ?? const NumericAxis(),
          series: widget.series,
        ),
      ),
    );
  }
}

/// Circular charts (category breakdown) with animations disabled.
class SafeSfCircularChart extends StatefulWidget {
  const SafeSfCircularChart({
    super.key,
    required this.series,
    this.height = 280,
    this.width,
    this.legend,
    this.tooltipBehavior,
    this.dataKey,
  });

  final List<CircularSeries<dynamic, dynamic>> series;
  final double height;
  final double? width;
  final Legend? legend;
  final TooltipBehavior? tooltipBehavior;
  final Object? dataKey;

  @override
  State<SafeSfCircularChart> createState() => _SafeSfCircularChartState();
}

class _SafeSfCircularChartState extends State<SafeSfCircularChart> {
  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return SizedBox(height: widget.height, width: widget.width);
    }

    if (widget.series.isEmpty) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(child: Text('No chart data')),
      );
    }

    final chartKey = widget.dataKey ?? widget.series.length;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: SfCircularChart(
          key: ValueKey<Object>(chartKey),
          legend: widget.legend ?? const Legend(isVisible: true),
          tooltipBehavior: widget.tooltipBehavior,
          series: widget.series,
        ),
      ),
    );
  }
}
