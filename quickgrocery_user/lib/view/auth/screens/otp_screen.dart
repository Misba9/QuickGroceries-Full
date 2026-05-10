import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

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
    final provider = Provider.of<AuthService>(context);
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
                  Text(
                    'please_type_verification_code'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('to'.tr(), style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        'your_mobile_number'.tr(),
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * .05),
                  PinCodeTextField(
                    controller: provider.opController,
                    enableActiveFill: true,
                    cursorColor: AppColor.primary,
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
                      activeFillColor: AppColor.primary,
                      disabledColor: AppColor.primary,
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
                    isLoading: provider.isLoading,
                    label: 'continue'.tr(),
                    onTap: () async {
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const LandingScreen()));
                      if (provider.opController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("incorrect_otp".tr()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        provider.signInWithOTP(
                          provider.opController.text,
                          context,
                        );
                      }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('dont_receive_otp'.tr()),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {},
                        child: Text('resend'.tr()),
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
