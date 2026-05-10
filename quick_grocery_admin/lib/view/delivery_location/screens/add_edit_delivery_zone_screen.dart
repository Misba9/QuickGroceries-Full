import 'package:quick_grocery_admin/dabshboard.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_location/services/delivery_zone_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class AddEditDeliveryZoneScreen extends StatefulWidget {
  const AddEditDeliveryZoneScreen({super.key});

  @override
  State<AddEditDeliveryZoneScreen> createState() =>
      _AddEditDeliveryZoneScreenState();
}

class _AddEditDeliveryZoneScreenState extends State<AddEditDeliveryZoneScreen> {
  @override
  void dispose() {
    // Reset fields when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeliveryZoneService>(context, listen: false).resetFields();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeliveryZoneService>(context);
    final isEditing = provider.editingZoneId != null;

    return Scaffold(
      body: Column(
        children: [
          PrimaryAppBar(isBackButton: true),
          AppSpacing.h20,
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset('assets/icons/location.svg'),
                              AppSpacing.w10,
                              Text(
                                isEditing
                                    ? 'Edit Delivery Zone'
                                    : 'Add New Delivery Zone',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Zone Name'),
                                    AppSpacing.h10,
                                    PrimaryTextField(
                                      controller: provider.zoneNameController,
                                      hintText: 'Ex: North Zone',
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.w20,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('City'),
                                    AppSpacing.h10,
                                    PrimaryTextField(
                                      controller: provider.cityController,
                                      hintText: 'Ex: Mumbai',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Charge (₹)'),
                                    AppSpacing.h10,
                                    TextField(
                                      controller:
                                          provider.deliveryChargeController,
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        hintText: 'Ex: 50.00',
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 14,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 0.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 0.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColor.primary,
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset('assets/icons/location.svg'),
                              AppSpacing.w10,
                              Text(
                                'Pin Codes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: provider.pinCodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter pin code (e.g., 400001)',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 0.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 0.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: AppColor.primary,
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AppSpacing.w10,
                              ElevatedButton.icon(
                                onPressed: () {
                                  provider.addPinCode();
                                },
                                icon: Icon(Icons.add),
                                label: Text('Add'),
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
                          AppSpacing.h20,
                          Consumer<DeliveryZoneService>(
                            builder: (context, service, _) {
                              if (service.pinCodesList.isEmpty) {
                                return Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'No pin codes added yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: service.pinCodesList.map((pinCode) {
                                  return Chip(
                                    label: Text(pinCode),
                                    deleteIcon: Icon(Icons.close, size: 18),
                                    onDeleted: () {
                                      service.removePinCode(pinCode);
                                    },
                                    backgroundColor: AppColor.primary
                                        .withOpacity(0.1),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          AppSpacing.h10,
                          Text(
                            'Note: You can add multiple pin codes for this zone. Each pin code should be unique.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              AppSpacing.w10,
                              Text(
                                'Zone Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h10,
                          Divider(),
                          AppSpacing.h10,
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Zone Type',
                                  'Pin Code Based',
                                  Icons.pin,
                                ),
                              ),
                              AppSpacing.w10,
                              Expanded(
                                child: _buildInfoCard(
                                  'Coverage',
                                  'Multiple Areas',
                                  Icons.map,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h10,
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.blue,
                                ),
                                AppSpacing.w10,
                                Expanded(
                                  child: Text(
                                    'Tip: You can define zones by pin codes, city, or map coordinates. For map-based zones, coordinates can be added in the future.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isEditing)
                            SizedBox(
                              height: 40,
                              width: 150,
                              child: OutlinedButton(
                                onPressed: () {
                                  provider.resetFields();
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Cancel'),
                              ),
                            ),
                          if (isEditing) AppSpacing.w10,
                          SizedBox(
                            height: 40,
                            width: 200,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: AppColor.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (isEditing) {
                                  provider.updateDeliveryZone(
                                    context,
                                    provider.editingZoneId!,
                                  );
                                } else {
                                  provider.addDeliveryZone(context);
                                }
                              },
                              child: provider.isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 1,
                                      ),
                                    )
                                  : Text(isEditing ? 'Update Zone' : 'Submit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    AppSpacing.h20,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColor.primary),
          AppSpacing.w10,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
