import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_appbar.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpAuthScreen extends StatelessWidget {
  const OtpAuthScreen({super.key});

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
              PrimaryAppBar(width: width, title: 'OTP Verification'),
              const Spacer(),
              Column(
                children: [
                  const Text(
                    'Please type the verifiation code sent',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: GlobalVariables.darkGrey,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'to',
                        style: TextStyle(
                          fontSize: 16,
                          color: GlobalVariables.darkGrey,
                        ),
                      ),
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
                    cursorColor: GlobalVariables.primary,
                    appContext: context,
                    length: 6,
                    pinTheme: PinTheme(
                      selectedFillColor: GlobalVariables.lightGrey,
                      inactiveFillColor: GlobalVariables.lightGrey,
                      activeColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      shape: PinCodeFieldShape.box,
                      inactiveColor: Colors.transparent,
                      selectedColor: Colors.transparent,
                      fieldHeight: height * .06,
                      fieldWidth: height * .06,
                      activeFillColor: GlobalVariables.lightGrey,
                      disabledColor: GlobalVariables.primary,
                    ),
                    onChanged: (v) {},
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
