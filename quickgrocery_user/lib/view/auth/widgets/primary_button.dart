import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  static const Color _labelColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onTap != null;
    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 55,
      child: Material(
        color: AppColor.primary,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _labelColor,
                    ),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      inherit: false,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: _labelColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
