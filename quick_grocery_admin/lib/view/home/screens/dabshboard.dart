import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/home/services/dash_board_services.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
    return Padding(
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
                ? Center(child: CircularProgressIndicator())
                : SfCartesianChart(
                    backgroundColor: Colors.white,
                    title: ChartTitle(
                      text: "Monthly Revenue",
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    legend: Legend(isVisible: true),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    primaryXAxis: CategoryAxis(
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      majorGridLines: MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      majorGridLines: MajorGridLines(width: 0.5),
                    ),
                    series: <CartesianSeries>[
                      SplineAreaSeries<RevenueData, String>(
                        dataSource: provider.revenueList, // Use fetched data
                        xValueMapper: (RevenueData data, _) => data.month,
                        yValueMapper: (RevenueData data, _) => data.revenue,
                        color: AppColor.primary.withOpacity(0.3),
                        borderColor: AppColor.primary,
                        borderWidth: 4,
                        dataLabelSettings: DataLabelSettings(isVisible: true),
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
