import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_safe_page.dart';
import 'package:quick_grocery_admin/core/responsive/admin_layout_widgets.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';

/// Vendor registration — scroll-safe (no nested [Scaffold] / [Expanded]).
class VendorAddScreen extends StatelessWidget {
  const VendorAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VendorService>();

    return AdminSafePage(
      debugLabel: 'Vendor Add',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Vendor Add', style: AppTextStyles.heading),
          const SizedBox(height: 24),
          Row(
            children: [
              SvgPicture.asset('assets/icons/userplus.svg'),
              AppSpacing.w10,
              const Text(
                'Add new Vendor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          AppSpacing.h20,
          WrapperWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/user.svg'),
                    AppSpacing.w10,
                    const Text('Vendor information'),
                  ],
                ),
                AppSpacing.h20,
                AdminLegacyFormSplit(
                  left: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
                      LayoutBuilder(
                        builder: (context, c) {
                          return Row(
                            children: [
                              const Text('+91'),
                              AppSpacing.w10,
                              SizedBox(
                                width: c.maxWidth > 48
                                    ? c.maxWidth - 48
                                    : c.maxWidth,
                                child: PrimaryTextField(
                                  controller: provider.phoneController,
                                  hintText: '9876543210',
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  right: AdminUploadSection(
                    label: 'Vendor image (1:1)',
                    buttonLabel: 'Upload image',
                    onTap: provider.pickImage,
                    preview: provider.imageBytes == null
                        ? null
                        : Image.memory(
                            provider.imageBytes!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.h20,
          WrapperWidget(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/user.svg'),
                    AppSpacing.w10,
                    const Text('Account information'),
                  ],
                ),
                AppSpacing.h20,
                AdminResponsiveRow(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/shop.svg'),
                    AppSpacing.w10,
                    const Text('Shop information'),
                  ],
                ),
                AppSpacing.h20,
                AdminLegacyFormSplit(
                  left: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
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
                    onTap: provider.pickImage2,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
