import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class NoServiceableAreaScreen extends StatelessWidget {
  const NoServiceableAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(24),
          fillMinHeight: true,
          centerWhenFilling: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                context.l10n.service_not_available,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.service_not_available_message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, AppPageRoutes.location());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  context.l10n.change_location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
