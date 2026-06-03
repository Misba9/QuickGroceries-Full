import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/widgets/delivery_logo.dart';
import 'package:quick_grocery_delivery/constants/delivery_branding.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/features/login/forgot_password/forgot_password_email_screen.dart';
import 'package:quick_grocery_delivery/features/login/services/login_service.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginScreenBody();
  }
}

class _LoginScreenBody extends StatelessWidget {
  const _LoginScreenBody();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginService>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          child: Column(
            children: [
              SizedBox(height: (height * .05).clamp(16.0, 40.0)),
              ClipPath(
                clipper: BottomClipper(),
                child: Container(
                  width: width,
                  height: (height * .25).clamp(120.0, 200.0),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DeliveryLogo(
                      height: (height * .22).clamp(110.0, 160.0),
                      showTitle: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                  Text(
                    DeliveryBranding.loginTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                      controller: provider.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: height * .06,
                    width: width,
                    decoration: BoxDecoration(
                      color: GlobalVariables.lightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: provider.passwordController,
                      obscureText: provider.obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: Icon(
                            provider.obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: provider.toggleObscurePassword,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20, top: 8),
                      child: TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordEmailScreen(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: GlobalVariables.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * .02),
                  Consumer<LoginService>(
                    builder: (context, p, _) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PrimaryButton(
                          height: height,
                          width: width,
                          title: 'Continue',
                          isLoading: p.isLoading,
                          onTap: () => p.login(context),
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
