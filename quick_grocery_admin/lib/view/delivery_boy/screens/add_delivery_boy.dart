import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/delivery_boy/services/delivery_boy_service.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DeliveryBoyService>(context);
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
                              SvgPicture.asset('assets/icons/userplus.svg'),
                              AppSpacing.w10,
                              Text(
                                'Add new Delivery Boy',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('First name'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .35,
                                    child: PrimaryTextField(
                                      controller: provider.firstNameController,
                                      hintText: 'Ex: Jhone',
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.w20,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Last name'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .35,
                                    child: PrimaryTextField(
                                      controller: provider.secondNameController,
                                      hintText: 'Ex: K',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .35,
                                    child: Row(
                                      children: [
                                        Text('+91'),
                                        AppSpacing.w10,
                                        Expanded(
                                          child: PrimaryTextField(
                                            controller:
                                                provider.phoneController,
                                            hintText: '9876543210',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.w20,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Licence Number'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .35,
                                    child: PrimaryTextField(
                                      controller: provider.licenceController,
                                      hintText: 'Ex: KL XXX0 XX06',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h20,
                                  Text('Address'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .35,
                                    child: PrimaryTextField(
                                      controller: provider.addressController,
                                      hintText: 'Ex: second street',
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.w20,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h20,
                                  Text('Vendor Image (Ratio 1:1)'),
                                  AppSpacing.h10,
                                  Center(
                                    child: Container(
                                      height:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      width:
                                          MediaQuery.of(context).size.width *
                                          .15,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Center(
                                        child: provider.imageBytes == null
                                            ? Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey.shade300,
                                              )
                                            : Image.memory(
                                                provider.imageBytes!,
                                              ),
                                      ),
                                    ),
                                  ),
                                  AppSpacing.h20,
                                  GestureDetector(
                                    onTap: () {
                                      provider.pickImage();
                                    },
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          .12,
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.add),
                                          AppSpacing.w10,
                                          Text('Upload Image'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
                              SvgPicture.asset('assets/icons/user.svg'),
                              AppSpacing.w10,
                              Text('Account information'),
                            ],
                          ),
                          AppSpacing.h20,
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h20,
                                  Text('Email'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .24,
                                    child: PrimaryTextField(
                                      controller: provider.emailController,
                                      hintText: 'Ex: jhone@gmail.com',
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.w15,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h20,
                                  Text('Password'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .24,
                                    child: PrimaryTextField(
                                      controller: provider.passwordController,
                                      hintText: 'Password',
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.w15,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSpacing.h20,
                                  Text('Confirm password'),
                                  AppSpacing.h10,
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * .24,
                                    child: PrimaryTextField(
                                      controller: provider.confirmController,
                                      hintText: 'Confirm password',
                                    ),
                                  ),
                                ],
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
                        width: 300,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: AppColor.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => provider.addDeliveryBoy(context),
                          child: provider.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 1,
                                  ),
                                )
                              : Text('Submit'),
                        ),
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
}
