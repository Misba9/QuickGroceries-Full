import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:quick_grocery_delivery/features/login/widgets/social_media_card.dart';
import 'package:quick_grocery_delivery/features/otp_auth/otp_auth_screen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final povider = Provider.of<LoginService>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: height * .05),
            ClipPath(
              clipper: BottomClipper(),
              child: Container(
                width: width,
                height: height * .25,
                decoration: const BoxDecoration(color: Colors.white),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Image.asset('assets/images/logo2.png'),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const Text(
                    'Quick Groceries Delivery',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: height * .04),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: GlobalVariables.lightGrey,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Log to continue',
                        style: TextStyle(color: GlobalVariables.darkGrey),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Divider(
                          thickness: 1,
                          color: GlobalVariables.lightGrey,
                        ),
                      ),
                      SizedBox(width: 20),
                    ],
                  ),
                  SizedBox(height: height * .04),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: height * .06,
                    width: width,
                    decoration: BoxDecoration(
                      color: GlobalVariables.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: povider.emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: height * .06,
                    width: width,
                    decoration: BoxDecoration(
                      color: GlobalVariables.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: povider.passwordController,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(height: height * .03),
                  Consumer<LoginService>(
                    builder: (context, p, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PrimaryButton(
                          height: height,
                          width: width,
                          title: 'Continue',
                          isLoading: false,
                          onTap: () => p.login(context),
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => const OtpAuthScreen()));
                        ),
                      );
                    },
                  ),
                  SizedBox(height: height * .03),
                  // const Row(
                  //   children: [
                  //     SizedBox(
                  //       width: 20,
                  //     ),
                  //     Expanded(
                  //       child: Divider(
                  //         thickness: 1,
                  //         color: GlobalVariables.lightGrey,
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 10,
                  //     ),
                  //     Text(
                  //       'or',
                  //       style: TextStyle(color: GlobalVariables.darkGrey),
                  //     ),
                  //     SizedBox(
                  //       width: 10,
                  //     ),
                  //     Expanded(
                  //       child: Divider(
                  //         thickness: 1,
                  //         color: GlobalVariables.lightGrey,
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 20,
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(
                  //   height: height * .03,
                  // ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     SocialMediaIcon(
                  //       width: width,
                  //       icon: AppIcons.google,
                  //     ),
                  //     SizedBox(
                  //       width: width * .17,
                  //     ),
                  //     SocialMediaIcon(
                  //       width: width,
                  //       icon: AppIcons.facebook,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, 0);
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(
      size.width - size.width / 4,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}
