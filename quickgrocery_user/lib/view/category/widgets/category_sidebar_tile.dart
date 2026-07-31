import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Compact left-rail tile for the Zepto/Blinkit-style sub-category list.
///
/// * **Inactive** — light grey image surface with the title underneath.
/// * **Active** — primary tint background, bolder title, and a primary
///   side bar on the left (animated in with [AppMotion.short]).
///
/// Designed for an 84 dp wide rail. Tap registers via [Material.InkWell]
/// so we get the proper ripple feedback.
class CategorySidebarTile extends StatelessWidget {
  const CategorySidebarTile({
    super.key,
    required this.image,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String image;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppColor.primary;

    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.emphasized,
      decoration: BoxDecoration(
        color: isSelected ? tint.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(14),
        ),
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: AppMotion.short,
                      curve: AppMotion.emphasized,
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppSurface.of(context).card
                            : AppSurface.of(context).subtle,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: isSelected
                              ? tint.withValues(alpha: 0.5)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                        boxShadow: isSelected ? AppShadow.dim : null,
                      ),
                      padding: EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        child: CachedImage(
                          url: image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppSurface.of(context).text
                            : AppSurface.of(context).textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
