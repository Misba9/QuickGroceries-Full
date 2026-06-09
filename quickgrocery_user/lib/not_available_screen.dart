import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

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
                context.l10n.we_are_closed,
                style: TextStyle(
                  fontSize: 18,
                  color: AppColor.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.h10,
            Text(context.l10n.store_offline_message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
