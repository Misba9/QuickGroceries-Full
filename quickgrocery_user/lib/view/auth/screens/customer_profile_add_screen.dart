import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';

class CustomerDetailsAddScreen extends StatelessWidget {
  const CustomerDetailsAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthService>(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircleAvatar(
                        backgroundImage: provider.image != null
                            ? FileImage(provider.image!)
                            : null,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          provider.pickImage();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryTextField(
                title: 'Name',
                controller: provider.nameController,
              ),
              AppSpacing.h20,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gender'),
                  AppSpacing.h10,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            provider.setGender('male');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: provider.selectedGender == 'male'
                                    ? AppColor.primary
                                    : Colors.grey,
                                width: provider.selectedGender == 'male'
                                    ? 2
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: provider.selectedGender == 'male'
                                  ? AppColor.primary.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.male,
                                  color: provider.selectedGender == 'male'
                                      ? AppColor.primary
                                      : Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Male',
                                  style: TextStyle(
                                    color: provider.selectedGender == 'male'
                                        ? AppColor.primary
                                        : Colors.grey,
                                    fontWeight:
                                        provider.selectedGender == 'male'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            provider.setGender('female');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: provider.selectedGender == 'female'
                                    ? AppColor.primary
                                    : Colors.grey,
                                width: provider.selectedGender == 'female'
                                    ? 2
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: provider.selectedGender == 'female'
                                  ? AppColor.primary.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.female,
                                  color: provider.selectedGender == 'female'
                                      ? AppColor.primary
                                      : Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Female',
                                  style: TextStyle(
                                    color: provider.selectedGender == 'female'
                                        ? AppColor.primary
                                        : Colors.grey,
                                    fontWeight:
                                        provider.selectedGender == 'female'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onTap: () => provider.registerUser(context),
                isLoading: provider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
