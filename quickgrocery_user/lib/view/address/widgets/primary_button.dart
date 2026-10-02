import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/loading/loading.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.height,
    required this.width,
    required this.title,
    required this.isLoading,
    required this.onTap,
  });

  final double height;
  final double width;
  final String title;
  final Function() onTap;
  final bool isLoading;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height * .06,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColor.primary,
        ),
        child: Center(
          child: isLoading
              ? AppLoading.spinner(size: 22, color: Colors.white)
              : Text(
                  title,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
