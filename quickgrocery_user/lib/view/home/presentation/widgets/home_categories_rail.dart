import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/category_model.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_section_slot.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_status_views.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Horizontal category chips — Blinkit-style rail.
class HomeCategoriesRail extends ConsumerWidget {
  const HomeCategoriesRail({super.key});

  static const double cardWidth = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesStreamProvider);
    final appContentAsync = ref.watch(appContentStreamProvider);
    final appContent = appContentAsync.value ?? AppContentConfig.defaults;
    final contentLoading =
        appContentAsync.isLoading && !appContentAsync.hasValue;

    if (!appContent.showShopCategory && !contentLoading) {
      return const SizedBox.shrink();
    }

    final loading = async.isLoading && !async.hasValue;
    final Widget body;
    if (async.hasError && !async.hasValue) {
      body = HomeErrorView(
        message: 'Couldn\'t load categories',
        onRetry: () => ref.invalidate(categoriesStreamProvider),
      );
    } else {
      final categories = async.asData?.value ?? const <CategoryModel>[];
      if (categories.isEmpty && !loading) {
        body = const HomeEmptyView(
          message: 'No categories available yet.',
          icon: Icons.category_outlined,
        );
      } else {
        body = SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final c = categories[i];
              return _CategoryRailCard(
                key: ValueKey('cat-${c.id.isNotEmpty ? c.id : c.name}'),
                category: c,
              );
            },
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: appContent.shopCategoryHeading,
          isLoading: contentLoading,
          actionLabel: context.l10n.see_all,
          onAction: () => legacy.Provider.of<HomeProvider>(
            context,
            listen: false,
          ).onSelectedChange(1),
        ),
        HomeSectionSlot(
          loading: loading,
          shimmer: AppLoading.categoryRail,
          minHeight: 128,
          child: body,
        ),
      ],
    );
  }
}

class _CategoryRailCard extends StatelessWidget {
  const _CategoryRailCard({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return SizedBox(
      width: HomeCategoriesRail.cardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadow.cardOf(context),
        ),
        child: Material(
          color: AppSurface.of(context).card,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryScreen(category: category.name),
                ),
              );
            },
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppSurface.of(context).card,
                    AppSurface.of(context).subtle.withValues(alpha: 0.35),
                  ],
                ),
                border: Border.all(color: AppSurface.of(context).border),
              ),
              padding: EdgeInsets.fromLTRB(8, 10, 8, 8),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppSurface.of(context).card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppSurface.of(context).border.withValues(alpha: 0.5),
                        ),
                      ),
                      padding: EdgeInsets.all(8),
                      child: CachedImage(
                        url: category.image,
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.circular(10),
                        memCacheWidth: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: AppSurface.of(context).textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
