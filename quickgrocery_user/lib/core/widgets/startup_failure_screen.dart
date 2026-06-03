import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';

/// Shown when Firebase fails to start after retries (e.g. no network).
class StartupFailureScreen extends StatelessWidget {
  const StartupFailureScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: KeyboardSafeBody(
            padding: const EdgeInsets.all(24),
            fillMinHeight: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                Icon(
                  Icons.cloud_off_outlined,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 20),
                Text(
                  'Can’t connect',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We couldn’t start the app. Check your internet connection '
                  'and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await onRetry();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
