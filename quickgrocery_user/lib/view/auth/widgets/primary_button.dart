import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/loading/loading.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final enabled = !isLoading && onTap != null;
    return SizedBox(
      width: width / 1,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          backgroundColor: AppColor.primary,
        ),
        onPressed: enabled ? onTap : null,
        child: isLoading
            ? AppLoading.spinner(size: 22, color: Colors.white)
            : Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }
}
