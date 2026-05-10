import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';

import 'package:pin_code_fields/pin_code_fields.dart';

class OtpAuthScreen extends StatefulWidget {
  static String route = 'otpScreen';
  const OtpAuthScreen({super.key});

  @override
  State<OtpAuthScreen> createState() => _OtpAuthScreenState();
}

class _OtpAuthScreenState extends State<OtpAuthScreen> {
  String otp = '';
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),
              Column(
                children: [
                  const Text(
                    'Please type the verifiation code sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('to', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      Text(
                        '+91 8769470312',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .05),
                  PinCodeTextField(
                    enableActiveFill: true,
                    cursorColor: Colors.green,
                    appContext: context,
                    length: 6,
                    pinTheme: PinTheme(
                      selectedFillColor: Colors.grey.shade200,
                      inactiveFillColor: Colors.grey.shade200,
                      activeColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      shape: PinCodeFieldShape.box,
                      inactiveColor: Colors.transparent,
                      selectedColor: Colors.transparent,
                      fieldHeight: height * .06,
                      fieldWidth: height * .06,
                      activeFillColor: Colors.grey.shade200,
                      disabledColor: Colors.green,
                    ),
                    onChanged: (v) {
                      setState(() {
                        otp = v;
                      });
                    },
                    onCompleted: (v) {},
                  ),
                  SizedBox(height: height * .05),
                  PrimaryButton(
                    height: height,
                    width: width,
                    title: 'Verify',
                    isLoading: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Dont receive the OTP?'),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {},
                        child: const Text('Resend'),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
