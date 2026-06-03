import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/view/combo/presentation/providers/combo_providers.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/combo/presentation/widgets/combo_offer_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';

/// Horizontal list of combo offers for the Offers hub.
class ComboOffersSection extends ConsumerWidget {
  const ComboOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeComboOffersProvider);

    return async.when(
      skipLoadingOnReload: false,
      loading: () => const _ComboSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (combos) {
        if (combos.isEmpty) return const SizedBox.shrink();
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Combo offers',
                subtitle: 'Curated bundles at best prices',
                icon: Icons.shopping_basket_outlined,
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 380,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(right: 16),
                  itemCount: combos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final combo = combos[i];
                    return SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.82,
                      child: ComboOfferCard(
                        combo: combo,
                        onTap: () => _openDetail(context, combo),
                        onAdd: () => _openDetail(context, combo, addOnOpen: true),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
      },
    );
  }

  void _openDetail(
    BuildContext context,
    ComboOfferModel combo, {
    bool addOnOpen = false,
  }) {
    Navigator.of(context).push(
      AppPageRoutes.comboDetail(combo: combo, addToCartOnLoad: addOnOpen),
    );
  }
}

class _ComboSkeleton extends StatelessWidget {
  const _ComboSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Combo offers',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: AppSurface.subtle,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          ),
        ],
    );
  }
}
