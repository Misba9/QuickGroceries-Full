import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quick_grocery_admin/dash_board_services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/widgets/safe_syncfusion_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    Provider.of<DashBoardServices>(context, listen: false).getCustomers();
    Provider.of<DashBoardServices>(context, listen: false).getVendors();
    Provider.of<DashBoardServices>(context, listen: false).getOrders();
    Provider.of<DashBoardServices>(context, listen: false).getProducts();
    Provider.of<DashBoardServices>(context, listen: false).fetchRevenueData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashBoardServices>(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset('assets/icons/chart.svg'),
              AppSpacing.w10,
              Text('Business analytics'),
            ],
          ),
          AppSpacing.h10,
          Row(
            children: [
              Expanded(
                child: WrapperWidget(
                  child: Column(
                    children: [
                      Text(
                        'Total Customers',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      AppSpacing.h20,
                      provider.customers == null
                          ? SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 1,
                              ),
                            )
                          : Text(
                              provider.customers!.length.toString(),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              AppSpacing.w20,
              Expanded(
                child: WrapperWidget(
                  child: Column(
                    children: [
                      Text(
                        'Total Vendors',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      AppSpacing.h20,
                      provider.vendors == null
                          ? SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 1,
                              ),
                            )
                          : Text(
                              provider.vendors!.length.toString(),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              AppSpacing.w20,
              Expanded(
                child: WrapperWidget(
                  child: Column(
                    children: [
                      Text(
                        'Total Orders',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      AppSpacing.h20,
                      provider.orders == null
                          ? SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 1,
                              ),
                            )
                          : Text(
                              provider.orders!.length.toString(),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.h20,
          Row(
            children: [
              Expanded(
                child: WrapperWidget(
                  child: Column(
                    children: [
                      Text(
                        'Total Products',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      AppSpacing.h20,
                      provider.products == null
                          ? SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: AppColor.primary,
                                strokeWidth: 1,
                              ),
                            )
                          : Text(
                              provider.products!.length.toString(),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              AppSpacing.w20,
              Expanded(
                child: WrapperWidget(
                  child: Column(
                    children: [
                      Text(
                        'Total Revenue',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                      AppSpacing.h20,
                      Text(
                        "₹${provider.totalRevenue}",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.h20,
          Row(
            children: [
              SvgPicture.asset('assets/icons/sale.svg'),
              AppSpacing.w10,
              Text('Revenue'),
            ],
          ),
          AppSpacing.h10,
          WrapperWidget(
            child: provider.revenueList.isEmpty
                ? const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SafeSfCartesianChart(
                    height: 280,
                    dataKey: provider.revenueList.length,
                    backgroundColor: Colors.white,
                    title: ChartTitle(
                      text: 'Monthly Revenue',
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    legend: const Legend(isVisible: true),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    primaryXAxis: CategoryAxis(
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      majorGridLines: const MajorGridLines(width: 0.5),
                    ),
                    series: <CartesianSeries<RevenueData, String>>[
                      SplineAreaSeries<RevenueData, String>(
                        animationDuration: 0,
                        dataSource: provider.revenueList,
                        xValueMapper: (RevenueData data, _) => data.month,
                        yValueMapper: (RevenueData data, _) => data.revenue,
                        color: AppColor.primary.withValues(alpha: 0.3),
                        borderColor: AppColor.primary,
                        borderWidth: 4,
                        dataLabelSettings:
                            const DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class RevenueData {
  final String month;
  final double revenue;
  RevenueData(this.month, this.revenue);
}

class WrapperWidget extends StatelessWidget {
  const WrapperWidget({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        return Container(
          padding: const EdgeInsets.all(15),
          width: w.isFinite ? w : null,
          constraints: const BoxConstraints(minWidth: 0),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
    );
  }
}

class PrimaryTextField extends StatelessWidget {
  const PrimaryTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Optional: Rounded corners
          borderSide: BorderSide(
            color: Colors.grey, // Border color
            width: 0.5, // Reduced border thickness
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 0.5, // Border thickness when not focused
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColor.primary, width: 0.8),
        ),
      ),
    );
  }
}
