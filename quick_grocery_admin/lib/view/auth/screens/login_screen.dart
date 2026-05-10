import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/auth/services/login_service.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LoginService>(context);
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    child: Image.asset('assets/images/logo.png'),
                  ),
                  AppSpacing.h10,
                  Text(
                    'Broomerce',
                    style: TextStyle(
                      fontSize: 40,
                      color: const Color.fromARGB(255, 249, 115, 85),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.h10,
                  Text('Welcome Back to admin login'),
                  AppSpacing.h20,
                  Text('Your email'),
                  AppSpacing.h10,
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .40,
                    child: PrimaryTextField(
                      controller: provider.emailController,
                      hintText: 'Email',
                    ),
                  ),
                  AppSpacing.h20,
                  Text('Password'),
                  AppSpacing.h10,
                  SizedBox(
                    width: MediaQuery.of(context).size.width * .40,
                    child: PrimaryTextField(
                      controller: provider.passwordController,
                      hintText: 'password',
                    ),
                  ),
                  AppSpacing.h20,
                  AppSpacing.h20,
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width / 2.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColor.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => provider.signIn(context),
                      child: provider.isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1,
                              ),
                            )
                          : Text('LOGIN'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
