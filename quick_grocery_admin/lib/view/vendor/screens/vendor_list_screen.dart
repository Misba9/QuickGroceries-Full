import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_global_top_bar.dart';
import 'package:quick_grocery_admin/view/home/widgets/admin_top_bar_actions.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_security_sheet.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_details.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  @override
  void initState() {
    Provider.of<VendorService>(context, listen: false).gettVendors();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/userplus.svg'),
                      AppSpacing.w10,
                      Expanded(
                        child: Text(
                          'Vendor List',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h20,
                  WrapperWidget(
                    child: Column(
                      children: [
                        Consumer<VendorService>(
                          builder: (context, p, _) {
                            if (p.vendors == null) {
                              return LinearProgressIndicator();
                            }
                            return LayoutBuilder(
                              builder: (context, c) {
                                final colSpace =
                                    (c.maxWidth * 0.03).clamp(8.0, 24.0);
                                final dataTable = DataTable(
                                  columnSpacing: colSpace,
                                  dataRowHeight: 70,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'SL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Shop Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Contact Info',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total Products',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total Orders',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Action',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: List.generate(p.vendors!.length, (index) {
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 260,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                            ),
                                            height: 50,
                                            width: 50,
                                            child: Image.network(
                                              p.vendors![index].shopImage,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              p.vendors![index].shopName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.vendors![index].phone,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            p.vendors![index].email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: p.vendors![index].isActive
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                      ),
                                      child: p.vendors![index].isActive
                                          ? Text('Active')
                                          : Text('InActive'),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.deepOrange.shade100,
                                      ),
                                      child: Text("0"),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.deepOrange.shade100,
                                      ),
                                      child: Text("0"),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.security,
                                            color: Colors.blueGrey,
                                          ),
                                          tooltip: 'Account security',
                                          onPressed: () {
                                            final v = p.vendors![index];
                                            PartnerSecuritySheet.show(
                                              context,
                                              role: 'vendor',
                                              partnerId: v.id,
                                              email: v.email,
                                              isActive: v.isActive,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            color: AppColor.primary,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    VendorDetailsScreen(
                                                      vendorId:
                                                          p.vendors![index].id,
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
                                );
                                return adminScrollableDataTable(
                                  viewportWidth: c.maxWidth,
                                  dataTable: dataTable,
                                );
                              },
                            );
                          },
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

class PrimaryAppBar extends StatelessWidget {
  const PrimaryAppBar({super.key, this.isBackButton = false, this.title});
  final bool isBackButton;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: AdminGlobalTopBar.barHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (isBackButton)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: 'Back',
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title ?? (isBackButton ? 'Details' : 'Quick Grocery Admin'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  const AdminTopBarActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
