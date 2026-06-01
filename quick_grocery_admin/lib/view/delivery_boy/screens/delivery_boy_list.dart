import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/delivery_boy/widgets/active_riders_live_map.dart';
import 'package:quick_grocery_admin/view/delivery_boy/widgets/delivery_boy_orders_sheet.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_security_sheet.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryBoysScreen extends StatefulWidget {
  const DeliveryBoysScreen({super.key});

  @override
  State<DeliveryBoysScreen> createState() => _DeliveryBoysScreenState();
}

class _DeliveryBoysScreenState extends State<DeliveryBoysScreen> {
  @override
  void initState() {
    Provider.of<DeliveryBoyService>(context, listen: false).getDeliveryBoys();
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
                  Consumer<DeliveryBoyService>(
                    builder: (context, svc, _) => AdminLiveSyncBar(
                      state: svc.deliverySyncState,
                      label: 'Delivery team',
                    ),
                  ),
                  AppSpacing.h10,
                  const ActiveRidersLiveMap(),
                  AppSpacing.h15,
                  WrapperWidget(
                    child: Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, c) {
                            final narrow = c.maxWidth < 560;
                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Delivery Boys',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSpacing.h10,
                                  TextField(
                                    autofocus: false,
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      prefixIcon: Icon(Icons.search),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward,
                                          color: AppColor.primary,
                                        ),
                                        onPressed: () {},
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: (value) {},
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Delivery Boys',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.w10,
                                SizedBox(
                                  width: (c.maxWidth * 0.45).clamp(200.0, 400.0),
                                  child: TextField(
                                    autofocus: false,
                                    decoration: InputDecoration(
                                      hintText: 'Search...',
                                      prefixIcon: Icon(Icons.search),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.arrow_forward,
                                          color: AppColor.primary,
                                        ),
                                        onPressed: () {},
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: (value) {},
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        AppSpacing.h10,
                        Divider(color: Colors.grey.shade300),
                        AppSpacing.h10,
                      ],
                    ),
                  ),
                AppSpacing.h20,
                WrapperWidget(
                  child: Column(
                    children: [
                      Consumer<DeliveryBoyService>(
                        builder: (context, p, _) {
                          if (p.deliveryBoys == null) {
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
                                  'Name',
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
                                  'Disable/Enable',
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
                            rows: List.generate(p.deliveryBoys!.length, (
                              index,
                            ) {
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 220,
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
                                              p.deliveryBoys![index].image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              p.deliveryBoys![index].firstName,
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
                                            p.deliveryBoys![index].phone,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            p.deliveryBoys![index].email,
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
                                        color: p.deliveryBoys![index].isActive
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                      ),
                                      child: p.deliveryBoys![index].isActive
                                          ? Text('Active')
                                          : Text('Disabled'),
                                    ),
                                  ),
                                  DataCell(
                                    Switch(
                                      value: p.deliveryBoys![index].isActive,
                                      onChanged: (v) {
                                        p.changeStatus(
                                          p.deliveryBoys![index].id,
                                          v,
                                        );
                                      },
                                    ),
                                  ),
                                  DataCell(
                                    p.ordersStatsLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : DeliveryBoyTotalOrdersCell(
                                            stats: p.statsFor(
                                              p.deliveryBoys![index].id,
                                            ),
                                            onTap: () {
                                              final rider =
                                                  p.deliveryBoys![index];
                                              DeliveryBoyOrdersSheet.show(
                                                context,
                                                rider: rider,
                                                stats: p.statsFor(rider.id),
                                                orders: p.ordersFor(rider.id),
                                              );
                                            },
                                          ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.security,
                                            color: Colors.blueGrey,
                                          ),
                                          tooltip: 'Account security',
                                          onPressed: () {
                                            final d = p.deliveryBoys![index];
                                            PartnerSecuritySheet.show(
                                              context,
                                              role: 'delivery',
                                              partnerId: d.id,
                                              email: d.email,
                                              isActive: d.isActive,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            p.showDeleteDialog(
                                              context,
                                              p.deliveryBoys![index].id,
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
