import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';

/// Offer hub category — scrolls to a section on the Offers page.
enum OfferHubCategory {
  megaSale('Mega Sale', Icons.local_fire_department_rounded, Color(0xFFFFF3E8)),
  comboOffers('Combo Offers', Icons.shopping_basket_outlined, Color(0xFFE8F5FF)),
  flashSale('Flash Sale', Icons.bolt_rounded, Color(0xFFFFF8E1)),
  freshDeals('Fresh Deals', Icons.eco_outlined, Color(0xFFE8F8EF)),
  limited('Limited Offers', Icons.timer_outlined, Color(0xFFF3E8FF));

  const OfferHubCategory(this.label, this.icon, this.tint);

  final String label;
  final IconData icon;
  final Color tint;
}

/// Horizontal rectangular chips replacing circular story orbs.
class OfferCategoryChips extends StatelessWidget {
  const OfferCategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final OfferHubCategory selected;
  final ValueChanged<OfferHubCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        physics: const BouncingScrollPhysics(),
        itemCount: OfferHubCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final cat = OfferHubCategory.values[i];
          final active = cat == selected;
          return _Chip(
            category: cat,
            active: active,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(cat);
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.category,
    required this.active,
    required this.onTap,
  });

  final OfferHubCategory category;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColor.primary.withValues(alpha: 0.22) : category.tint,
      borderRadius: BorderRadius.circular(AppRadii.md),
      elevation: active ? 2 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: active ? AppColor.primary : AppSurface.of(context).border,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 18,
                color: active ? AppSurface.of(context).textPrimary : AppSurface.of(context).textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                category.label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: active
                      ? AppSurface.of(context).textPrimary
                      : AppSurface.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
