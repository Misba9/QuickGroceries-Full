import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/category/presentation/utils/category_grid_layout.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Category tile rendered in the home grid.
///
/// Layout contract — overflow-proof on any device:
///   ┌────────────────────────┐  ← cell (sized by parent grid)
///   │ ┌────────────────────┐ │  ← Expanded → square via LayoutBuilder
///   │ │     image card     │ │     (side = min(maxW, maxH))
///   │ │                    │ │
///   │ └────────────────────┘ │
///   │ ── 8 px gap ──         │
///   │  Label · up to 2 lines │  ← flexible text block (ellipsis)
///   └────────────────────────┘
///
/// Grids should use [CategoryGridLayout.childAspectRatio] so cell height
/// matches this column layout (including accessibility text scaling).
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.all(AppRadii.md),
      child: InkWell(
        borderRadius: AppRadii.all(AppRadii.md),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryScreen(category: category.name),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadii.all(AppRadii.md),
                          border: Border.all(color: AppSurface.border),
                          boxShadow: AppShadow.dim,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: CachedImage(
                          url: category.image,
                          fit: BoxFit.contain,
                          borderRadius: AppRadii.all(AppRadii.sm),
                          memCacheWidth: 240,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: CategoryGridLayout.homeImageGap),
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                category.name,
                maxLines: CategoryGridLayout.nameMaxLines,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: CategoryGridLayout.nameFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppSurface.textPrimary,
                  height: CategoryGridLayout.nameLineHeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
