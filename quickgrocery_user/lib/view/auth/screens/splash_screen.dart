import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          fillMinHeight: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  SizedBox(height: size.height * .06),
                  Center(child: Image.asset('assets/images/logo.png')),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(15),
                margin: const EdgeInsets.only(top: 15, bottom: 8),
                constraints: BoxConstraints(
                  minHeight: 160,
                  maxHeight: size.width / 1.4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'buy_groceries_easily'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.h20,
                    PrimaryButton(
                      label: 'continue'.tr(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
