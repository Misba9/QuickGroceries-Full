import 'package:quick_grocery_admin/dabshboard.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/platform_fee/services/platform_fee_service.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class PlatformFeeScreen extends StatefulWidget {
  const PlatformFeeScreen({super.key});

  @override
  State<PlatformFeeScreen> createState() => _PlatformFeeScreenState();
}

class _PlatformFeeScreenState extends State<PlatformFeeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch charges when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PlatformFeeService>(context, listen: false).fetchCharges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlatformFeeService>(context);

    return Scaffold(
      body: Column(
        children: [
          PrimaryAppBar(),
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
                              SvgPicture.asset('assets/icons/chart.svg'),
                              AppSpacing.w10,
                              Text(
                                'Platform Fee',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          Text(
                            'Update platform fee',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          AppSpacing.h20,
                          // Platform Fee
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Platform Fee (₹)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.h10,
                              TextField(
                                controller: provider.platformFeeController,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter platform fee',
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
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
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
                            provider.updateCharges(context);
                          },
                          child: provider.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  ),
                                )
                              : Text('Update Fee'),
                        ),
                      ),
                    ),
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
}
