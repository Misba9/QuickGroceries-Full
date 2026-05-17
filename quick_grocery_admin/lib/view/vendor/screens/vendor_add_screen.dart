import 'dart:io';

import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class VendorAddScreen extends StatelessWidget {
  const VendorAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VendorService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ListView(
                children: [
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/userplus.svg'),
                      AppSpacing.w10,
                      Text(
                        'Add new Vendor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                            Text('Vendor information'),
                          ],
                        ),
                        AppSpacing.h20,
                        AdminLegacyFormSplit(
                          left: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('First name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.firstNameController,
                                hintText: 'Ex: Jhone',
                              ),
                              AppSpacing.h20,
                              const Text('Last name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.secondNameController,
                                hintText: 'Ex: KP',
                              ),
                              AppSpacing.h20,
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
                          right: AdminUploadSection(
                            label: 'Vendor image (1:1)',
                            buttonLabel: 'Upload image',
                            onTap: () => provider.pickImage(),
                            preview: provider.imageBytes == null
                                ? null
                                : Image.memory(
                                    provider.imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        AppSpacing.h20,
                      ],
                    ),
                  ),
                  AppSpacing.h20,
                  WrapperWidget(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/user.svg'),
                            AppSpacing.w10,
                            Text('Account information'),
                          ],
                        ),
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
                  WrapperWidget(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/icons/shop.svg'),
                            AppSpacing.w10,
                            Text('Shop information'),
                          ],
                        ),
                        AdminLegacyFormSplit(
                          left: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Shop name'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                controller: provider.shopNameController,
                                hintText: 'Ex: Nexa',
                              ),
                              AppSpacing.h20,
                              const Text('Shop address'),
                              AppSpacing.h10,
                              PrimaryTextField(
                                hintText: 'Ex: South road bihar',
                                controller: provider.shopAddressController,
                              ),
                            ],
                          ),
                          right: AdminUploadSection(
                            label: 'Shop logo (1:1)',
                            buttonLabel: 'Upload logo',
                            onTap: () => provider.pickImage2(),
                            preview: provider.imageBytes2 == null
                                ? null
                                : Image.memory(
                                    provider.imageBytes2!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.h20,
                  AdminPrimaryButton(
                    label: 'Submit',
                    isLoading: provider.isLoading,
                    onPressed: () => provider.addVendor(context),
                  ),
                  AppSpacing.h20,
                  AppSpacing.h20,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
