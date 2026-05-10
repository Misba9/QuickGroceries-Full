import 'package:quick_grocery_admin/dabshboard.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quick_grocery_admin/view/delivery_location/screens/add_edit_delivery_zone_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryLocationListScreen extends StatefulWidget {
  const DeliveryLocationListScreen({super.key});

  @override
  State<DeliveryLocationListScreen> createState() =>
      _DeliveryLocationListScreenState();
}

class _DeliveryLocationListScreenState
    extends State<DeliveryLocationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneService>(
        context,
        listen: false,
      ).fetchDeliveryZones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PrimaryAppBar(),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                WrapperWidget(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Zones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddEditDeliveryZoneScreen(),
                                ),
                              ).then((_) {
                                Provider.of<DeliveryZoneService>(
                                  context,
                                  listen: false,
                                ).fetchDeliveryZones();
                              });
                            },
                            icon: Icon(Icons.add),
                            label: Text('Add Zone'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: AppColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
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
                      Consumer<DeliveryZoneService>(
                        builder: (context, service, _) {
                          if (service.isLoading &&
                              service.deliveryZones == null) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (service.deliveryZones == null ||
                              service.deliveryZones!.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    AppSpacing.h10,
                                    Text(
                                      'No delivery zones found',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    AppSpacing.h10,
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddEditDeliveryZoneScreen(),
                                          ),
                                        ).then((_) {
                                          service.fetchDeliveryZones();
                                        });
                                      },
                                      child: Text('Add your first zone'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return DataTable(
                            columnSpacing:
                                MediaQuery.of(context).size.width * .05,
                            dataRowHeight: 80,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'SL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Zone Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'City',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Pin Codes',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Delivery Charge',
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
                                  'Action',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: List.generate(service.deliveryZones!.length, (
                              index,
                            ) {
                              final zone = service.deliveryZones![index];
                              return DataRow(
                                cells: [
                                  DataCell(Text((index + 1).toString())),
                                  DataCell(
                                    Text(
                                      zone.zoneName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(zone.city)),
                                  DataCell(
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 200,
                                      ),
                                      child: Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children:
                                            zone.pinCodes.take(3).map((pin) {
                                              return Chip(
                                                label: Text(
                                                  pin,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(2),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              );
                                            }).toList()..addAll(
                                              zone.pinCodes.length > 3
                                                  ? [
                                                      Chip(
                                                        label: Text(
                                                          '+${zone.pinCodes.length - 3}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                        padding: EdgeInsets.all(
                                                          2,
                                                        ),
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      '₹${zone.deliveryCharge.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: zone.isActive
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                      ),
                                      child: Text(
                                        zone.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: zone.isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: zone.isActive,
                                          onChanged: (value) {
                                            service.toggleZoneStatus(
                                              zone.id,
                                              zone.isActive,
                                            );
                                          },
                                        ),
                                        AppSpacing.w10,
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: AppColor.primary,
                                          ),
                                          onPressed: () {
                                            service.loadZoneForEdit(zone);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AddEditDeliveryZoneScreen(),
                                              ),
                                            ).then((_) {
                                              service.fetchDeliveryZones();
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext dialogContext) {
                                                return AlertDialog(
                                                  title: Text('Delete Zone'),
                                                  content: Text(
                                                    'Are you sure you want to delete "${zone.zoneName}"?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop();
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        service
                                                            .deleteDeliveryZone(
                                                              dialogContext,
                                                              zone.id,
                                                            );
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop();
                                                      },
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors.red,
                                                          ),
                                                      child: Text('Delete'),
                                                    ),
                                                  ],
                                                );
                                              },
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
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
