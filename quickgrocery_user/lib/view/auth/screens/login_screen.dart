import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/screens/firebase_diagnostic_screen.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AuthService>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          child: Column(
              children: [
                AppSpacing.h20,
                GestureDetector(
                  onLongPress: kDebugMode
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const FirebaseDiagnosticScreen(),
                            ),
                          );
                        }
                      : null,
                  child: Image.asset('assets/images/logo.png'),
                ),
                // Align(
                //   alignment: Alignment.topLeft,
                //   child: Text(
                //     context.l10n.fresh_groceries_delivered,
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
                            hintText: context.l10n.phone_number,
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
                  label: context.l10n.continueAction,
                  onTap: provider.isLoading
                      ? null
                      : () {
                          provider.clearPhoneAuthError();
                          if (provider.mobileController.text.length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.please_enter_valid_phone),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            provider.verifyPhoneNumber(context);
                          }
                        },
                ),
                AppSpacing.h15,
              ],
            ),
        ),
      ),
    );
  }
}
