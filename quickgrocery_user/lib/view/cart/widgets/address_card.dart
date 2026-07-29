import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_icons.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:provider/provider.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AddressService>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppColor.primary.withValues(alpha: 0.2),
              ),
              child: SizedBox(
                height: 30,
                child: Image.asset(AppIcons.home, color: Colors.white),
              ),
            ),
            AppSpacing.w10,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivering to ${provider.addresses![provider.selectedIndex].type} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Text(
                    "${provider.addresses![provider.selectedIndex].address}, ${provider.addresses![provider.selectedIndex].area}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, AppPageRoutes.address());
          },
          child: const Text(
            'Change',
            style: TextStyle(color: AppColor.primary),
          ),
        ),
      ],
    );
  }
}
