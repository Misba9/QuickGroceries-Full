import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';

/// Shown when bootstrap fails with no cached fallback data.
class BootstrapErrorScreen extends StatelessWidget {
  const BootstrapErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    this.isRetrying = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.of(context).scaffold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 52,
                  color: AppColor.primary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Couldn\'t load the store',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppSurface.of(context).textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                message.isEmpty
                    ? 'Check your connection and try again.'
                    : message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                  color: AppSurface.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: isRetrying ? null : onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isRetrying
                      ? const SizedBox(width: 22, height: 22, child: AppLoading.micro)
                      : Text(
                          'Try again',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
