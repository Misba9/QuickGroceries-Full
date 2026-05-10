import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Category tile rendered in the home grid.
///
/// Layout contract — overflow-proof on any device:
///   ┌────────────────────────┐  ← cell (sized by parent grid)
///   │ ┌────────────────────┐ │  ← Expanded → AspectRatio(1)
///   │ │     image card     │ │     keeps a square that *shrinks*
///   │ │                    │ │     to fit whatever vertical space
///   │ └────────────────────┘ │     the parent grants.
///   │ ── 8 px gap ──         │
///   │ ┌────────────────────┐ │  ← SizedBox(height: 32) reserves
///   │ │  Label · 2 lines   │ │     space for up to 2 lines of text
///   │ └────────────────────┘ │     so the image never has to.
///   └────────────────────────┘
///
/// The companion grid in `home_screen.dart` uses [LayoutBuilder] to
/// compute a `childAspectRatio` that exactly matches this layout, so
/// the tile renders pixel-perfect across small phones, large phones,
/// and tablets without manual breakpoints.
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
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
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
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppSurface.textPrimary,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
