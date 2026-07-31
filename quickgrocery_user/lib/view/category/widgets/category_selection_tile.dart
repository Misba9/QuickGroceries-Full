import 'package:flutter/material.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

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
            ),
            clipBehavior: Clip.antiAlias,
            child: CachedImage(
              url: image,
              width: double.infinity,
              height: 60,
              fit: BoxFit.cover,
              memCacheWidth: 200,
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
