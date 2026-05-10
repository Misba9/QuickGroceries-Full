import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';

class NotActiveScreen extends StatefulWidget {
  const NotActiveScreen({super.key});

  @override
  State<NotActiveScreen> createState() => _NotActiveScreenState();
}

class _NotActiveScreenState extends State<NotActiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'we_are_closed'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.h10,
            Text('store_offline_message'.tr(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
