import 'package:flutter/material.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';
import 'package:lottie/lottie.dart';

class CancellSuccesScreen extends StatelessWidget {
  const CancellSuccesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          fillMinHeight: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  LottieBuilder.asset('assets/lottie/no.json'),
                  const Text(
                    'Order Cancelled  Successfully',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              PrimaryButton(
              label: "Go Home",
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LandingScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
