import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/firebase/firebase_config_audit.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthService>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                AppSpacing.h20,
                Image.asset('assets/images/logo.png'),
                // Align(
                //   alignment: Alignment.topLeft,
                //   child: Text(
                //     'fresh_groceries_delivered'.tr(),
                //     style: TextStyle(fontSize: 20),
                //   ),
                // ),
                //  LottieBuilder.asset('assets/lottie/login.json'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('+91'),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          controller: provider.mobileController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'phone_number'.tr(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h10,
                if (provider.phoneAuthError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      provider.phoneAuthError!,
                      style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                    ),
                  ),
                  AppSpacing.h10,
                ],

                AppSpacing.h20,
                PrimaryButton(
                  isLoading: provider.isLoading,
                  label: 'continue'.tr(),
                  onTap: provider.isLoading
                      ? null
                      : () {
                          provider.clearPhoneAuthError();
                          if (provider.mobileController.text.length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("please_enter_valid_phone".tr()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            provider.verifyPhoneNumber(context);
                          }
                        },
                ),
                AppSpacing.h15,
                if (kDebugMode) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Text(
                      FirebaseConfigAudit.emulatorTestNumberHint(),
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
