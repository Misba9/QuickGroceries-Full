import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_icons.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/address/screens/add_address_screen.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/address/widgets/primary_button.dart';
import 'package:quickgrocery/view/cart/services/cart_service.dart';
import 'package:quickgrocery/view/cart/widgets/address_card.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/view/payment/services/payment_service.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PaymentService>(context);
    final addressService = Provider.of<AddressService>(context);
    final cartService = Provider.of<CartService>(context);
    final catService = Provider.of<CategoryService>(context);
    final homeService = Provider.of<HomeProvider>(context);

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //   PrimaryAppBar(width: width, title: 'Payment Method'),
              Consumer<AddressService>(
                builder: (context, p, _) {
                  if (p.addresses == null || p.addresses!.isEmpty) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddAdressScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              Text(context.l10n.add_address),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return const AddressCard();
                },
              ),
              AppSpacing.h20,
              Column(
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    child: PaymentTile(
                      onChanged: (v) {
                        provider.onPaymentMethodChange(false);
                      },
                      width: width,
                      groupValue: false,
                      isTrue: provider.isCashOnDelivery,
                      title: context.l10n.online_payment,
                      icon: AppIcons.mastercard,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInRight(
                    duration: const Duration(milliseconds: 800),
                    child: PaymentTile(
                      onChanged: (v) {
                        provider.onPaymentMethodChange(true);
                      },
                      groupValue: true,
                      isTrue: provider.isCashOnDelivery,
                      width: width,
                      title: context.l10n.cash_on_delivery,
                      icon: AppIcons.money,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              height: height,
              width: width,
              title: context.l10n.continueAction,
              isLoading: cartService.isLoading,
              onTap: () async {
                if (addressService.addresses == null ||
                    addressService.addresses!.isEmpty) {
                  AppSnackBar.error(
                    context.l10n.please_add_address,
                    context: context,
                  );
                } else {
                  if (provider.isCashOnDelivery) {
                    cartService.addCartItemto(
                      context,
                      catService.selectedProduct,
                      addressService.addresses![addressService.selectedIndex],
                      addressService.address,
                      addressService.latLng ?? homeService.currentLatLng,
                    );
                  } else {
                    // Legacy PaymentScreen cannot verify Razorpay server-side.
                    // Online payments must go through CheckoutScreen.
                    if (!context.mounted) return;
                    AppSnackBar.error(
                      'Please pay online from Checkout for secure payment.',
                      context: context,
                    );
                  }
                }
                // Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //         builder: (context) => const TrackinScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.width,
    required this.title,
    required this.icon,
    required this.isTrue,
    required this.groupValue,
    required this.onChanged,
  });

  final double width;
  final String title;
  final String icon;
  final bool isTrue;
  final bool groupValue;
  final Function(bool? v) onChanged;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      height: width * .20,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(height: 30, child: Image.asset(icon, fit: BoxFit.cover)),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Radio(value: isTrue, groupValue: groupValue, onChanged: onChanged),
        ],
      ),
    );
  }
}
