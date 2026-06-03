import 'package:flutter/material.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:lottie/lottie.dart';

/// Legacy success screen — prefer navigating directly to
/// [OrderTrackingScreen] after checkout.
class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, this.orderId});

  final String? orderId;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          fillMinHeight: true,
          centerWhenFilling: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: (width * 0.45).clamp(120.0, 280.0),
                child: LottieBuilder.asset(
                  'assets/lottie/success.json',
                  repeat: false,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order successful',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your order is being prepared. Track live updates on the next screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (orderId != null && orderId!.isNotEmpty)
                PrimaryButton(
                  label: 'Track order',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(
                          orderId: orderId!,
                          fromCheckout: true,
                        ),
                      ),
                    );
                  },
                ),
              if (orderId != null && orderId!.isNotEmpty)
                const SizedBox(height: 10),
              PrimaryButton(
                label: 'Go Home',
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
