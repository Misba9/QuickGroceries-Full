import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_appbar.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:quick_grocery_delivery/widgets/keyboard_safe_body.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpAuthScreen extends StatelessWidget {
  const OtpAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final pinSize = (width * 0.12).clamp(44.0, 52.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          fillMinHeight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryAppBar(width: width, title: 'OTP Verification'),
              const SizedBox(height: 24),
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
                  Flexible(
                    child: Text(
                      '+91 8769470312',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * .03),
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
                  fieldHeight: pinSize,
                  fieldWidth: pinSize,
                  activeFillColor: GlobalVariables.lightGrey,
                  disabledColor: GlobalVariables.primary,
                ),
                onChanged: (v) {},
                onCompleted: (v) {},
              ),
              SizedBox(height: height * .03),
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
        ),
      ),
    );
  }
}
