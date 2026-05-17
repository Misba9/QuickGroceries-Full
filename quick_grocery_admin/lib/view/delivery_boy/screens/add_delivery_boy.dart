import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
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
                          AdminResponsiveRow(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('First name'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.firstNameController,
                                    hintText: 'Ex: Jhone',
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Last name'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.secondNameController,
                                    hintText: 'Ex: K',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          AdminResponsiveRow(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Phone'),
                                  AppSpacing.h10,
                                  Row(
                                    children: [
                                      const Text('+91'),
                                      AppSpacing.w10,
                                      Expanded(
                                        child: PrimaryTextField(
                                          controller: provider.phoneController,
                                          hintText: '9876543210',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Licence number'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.licenceController,
                                    hintText: 'Ex: KL XXX0 XX06',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          AppSpacing.h20,
                          AdminResponsiveRow(
                            breakpoint: 640,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Address'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.addressController,
                                    hintText: 'Ex: second street',
                                  ),
                                ],
                              ),
                              AdminUploadSection(
                                label: 'Profile image (1:1)',
                                buttonLabel: 'Upload image',
                                onTap: provider.pickImage,
                                preview: provider.imageBytes == null
                                    ? null
                                    : Image.memory(
                                        provider.imageBytes!,
                                        fit: BoxFit.cover,
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
                              SvgPicture.asset('assets/icons/user.svg'),
                              AppSpacing.w10,
                              Text('Account information'),
                            ],
                          ),
                          AppSpacing.h20,
                          AdminResponsiveRow(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Email'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.emailController,
                                    hintText: 'Ex: jhone@gmail.com',
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Password'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.passwordController,
                                    hintText: 'Password',
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Confirm password'),
                                  AppSpacing.h10,
                                  PrimaryTextField(
                                    controller: provider.confirmController,
                                    hintText: 'Confirm password',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.h20,
                    AdminPrimaryButton(
                      label: 'Submit',
                      isLoading: provider.isLoading,
                      onPressed: () => provider.addDeliveryBoy(context),
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
