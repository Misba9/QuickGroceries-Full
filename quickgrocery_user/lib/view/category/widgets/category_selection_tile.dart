import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';

class CategorySelectionTile extends StatelessWidget {
  const CategorySelectionTile({
    super.key,
    required this.image,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });
  final String image;
  final String title;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: AppColor.primary) : null,
              borderRadius: BorderRadius.circular(6),
              color: isSelected
                  ? AppColor.primary.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
              image: DecorationImage(image: NetworkImage(image)),
            ),
          ),
        ),
        AppSpacing.h10,
        Text(title, style: const TextStyle(fontSize: 10)),
        AppSpacing.h10,
      ],
    );
  }
}
