import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_security_sheet.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorDetailsScreen extends StatefulWidget {
  const VendorDetailsScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    Provider.of<VendorService>(
      context,
      listen: false,
    ).getVendorDetails(widget.vendorId);
    Provider.of<VendorService>(
      context,
      listen: false,
    ).getOrders(widget.vendorId);
    Provider.of<VendorService>(
      context,
      listen: false,
    ).fetchProducts(widget.vendorId);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorService>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: Column(
        children: [
          PrimaryAppBar(isBackButton: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: provider.vendor == null && provider.products == null
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/userplus.svg'),
                            AppSpacing.w10,
                            const Text(
                              'Vendor details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.h20,
                        Expanded(
                          child: Column(
                            children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: AppColor.primary,
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Products'),
                                Tab(text: 'Orders'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                provider.vendor == null
                                    ? SizedBox()
                                    : Padding(
                                        padding: const EdgeInsets.all(15.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                              ),
                                              height: 150,
                                              width: 150,
                                              child: Image.network(
                                                provider.vendor!.shopImage,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            AppSpacing.h20,
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        provider
                                                            .vendor!
                                                            .shopName,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      AppSpacing.h10,
                                                      Text(
                                                        "Email : ${provider.vendor!.email}",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      Text(
                                                        "Phone : ${provider.vendor!.phone}",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            AppSpacing.h20,
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                final v = provider.vendor!;
                                                PartnerSecuritySheet.show(
                                                  context,
                                                  role: 'vendor',
                                                  partnerId: v.id,
                                                  email: v.email,
                                                  isActive: v.isActive,
                                                );
                                              },
                                              icon: const Icon(Icons.security),
                                              label: const Text('Account security'),
                                            ),
                                            AppSpacing.h20,
                                            Text('Shop information'),
                                            Text(
                                              "Location : ${provider.vendor!.shopAddress}",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            AppSpacing.h20,
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding: EdgeInsets.all(15),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColor.primary,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          'Total products :',
                                                          style: TextStyle(
                                                            color: AppColor
                                                                .primary,
                                                          ),
                                                        ),
                                                        AppSpacing.h10,
                                                        Text(
                                                          '0',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                AppSpacing.w10,
                                                Expanded(
                                                  child: Container(
                                                    padding: EdgeInsets.all(15),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColor.primary,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          'Total orders :',
                                                          style: TextStyle(
                                                            color: AppColor
                                                                .primary,
                                                          ),
                                                        ),
                                                        AppSpacing.h10,
                                                        Text(
                                                          '0',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            AppSpacing.h10,
                                            Center(
                                              child: SizedBox(
                                                height: 50,
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: provider.vendor!.isActive
                                                        ? Colors.red
                                                        : Colors.green,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    provider.changeStatus(
                                                      widget.vendorId,
                                                      !provider.vendor!.isActive,
                                                    );
                                                  },
                                                  child: Text(
                                                    provider.vendor!.isActive
                                                        ? 'Suspend'
                                                        : 'Activate',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                provider.products == null
                                    ? SizedBox()
                                    : DataTable(
                                        dataRowHeight: 70,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'SL',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Product Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Selling price',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Category',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Featured',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Active status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Action',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: List.generate(
                                          provider.products!.length,
                                          (index) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text((index + 1).toString()),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundImage:
                                                            provider
                                                                    .products![index]
                                                                    .image !=
                                                                ''
                                                            ? NetworkImage(
                                                                provider
                                                                    .products![index]
                                                                    .image,
                                                              )
                                                            : null,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        provider
                                                            .products![index]
                                                            .name,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    provider
                                                        .products![index]
                                                        .price,
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    provider
                                                        .products![index]
                                                        .category,
                                                  ),
                                                ),
                                                DataCell(
                                                  Switch(
                                                    value: provider
                                                        .products![index]
                                                        .isActive,
                                                    onChanged: (value) {},
                                                  ),
                                                ),
                                                DataCell(
                                                  Switch(
                                                    value: provider
                                                        .products![index]
                                                        .isActive,
                                                    onChanged: (value) {},
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons
                                                              .visibility_outlined,
                                                          color: Colors.blue,
                                                        ),
                                                        onPressed: () {},
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {},
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                provider.orders == null
                                    ? SizedBox()
                                    : DataTable(
                                        dataRowHeight: 70,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'SL',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Order ID',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Date',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Payment Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Total',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Order Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Action',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: List.generate(provider.orders!.length, (
                                          index,
                                        ) {
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text((index + 1).toString()),
                                              ),
                                              DataCell(
                                                Text(
                                                  provider.orders![index].id,
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  DateFormat(
                                                    "MMM d yyyy HH:mm:00",
                                                  ).format(
                                                    DateTime.parse(
                                                      provider
                                                          .orders![index]
                                                          .createdDate,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                provider.orders![index].isPaid
                                                    ? Container(
                                                        padding: EdgeInsets.all(
                                                          5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .green
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text('Paid'),
                                                      )
                                                    : Container(
                                                        padding: EdgeInsets.all(
                                                          5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .red
                                                              .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text('Unpaid'),
                                                      ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "₹${provider.orders![index].getTotalAmount().toStringAsFixed(0)}",
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  provider
                                                      .orders![index]
                                                      .orderStatus,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .visibility_outlined,
                                                        color: AppColor.primary,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                OrderDetailsScreen(
                                                                  order: provider
                                                                      .orders![index],
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
