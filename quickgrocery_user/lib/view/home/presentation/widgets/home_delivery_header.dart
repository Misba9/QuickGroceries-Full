import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/constants/app_icons.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/realtime/models/notification_item.dart';
import 'package:quickgrocery/realtime/providers/realtime_providers.dart';
import 'package:quickgrocery/realtime/utils/notification_navigation.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/delivery/domain/delivery_pricing_policy.dart';
import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';
import 'package:quickgrocery/view/app_content/presentation/widgets/animated_app_heading.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Pinned Blinkit/Zepto-style delivery strip + quick actions.
class HomeStickyDeliveryHeaderDelegate extends SliverPersistentHeaderDelegate {
  HomeStickyDeliveryHeaderDelegate({required this.gutter});

  final double gutter;

  static const double _contentHeight = 82;

  @override
  double get maxExtent => _contentHeight;

  @override
  double get minExtent => _contentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // LandingScreen already applied status-bar SafeArea — only a small
    // content gutter here (never MediaQuery.padding.top again).
    final topGutter = (gutter * 0.35).clamp(4.0, 8.0);

    final shadow = overlapsContent
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : AppShadow.dim;

    return ColoredBox(
      color: AppSurface.of(context).background,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, topGutter, gutter, 8),
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            gradient: AppGradients.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: shadow,
            border: Border.all(color: AppSurface.of(context).border.withValues(alpha: 0.55)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Consumer(
                builder: (context, ref, _) {
                  final appContentAsync = ref.watch(appContentStreamProvider);
                  final appContent =
                      appContentAsync.value ?? AppContentConfig.defaults;
                  final contentLoading =
                      appContentAsync.isLoading && !appContentAsync.hasValue;

                  final unreadAsync = ref.watch(unreadNotificationsCountProvider);
                  final unread = unreadAsync.when(
                    data: (v) => v,
                    loading: () => 0,
                    error: (_, __) => 0,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(context, AppPageRoutes.location());
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.brand(),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: AppShadow.primaryGlow,
                                ),
                                child: Center(
                                  child: Image.asset(
                                    AppIcons.location,
                                    width: 22,
                                    height: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AnimatedAppHeading(
                                            text: appContent.deliveryTimeText,
                                            isLoading: contentLoading,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.35,
                                              color: AppSurface.of(context).textPrimary,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        _ArrowPulse(),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    legacy.Consumer<AddressService>(
                                      builder: (_, address, __) {
                                        final label = address.address;
                                        return Text(
                                          label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: AppSurface.of(context).textMuted,
                                            height: 1.2,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _HeaderIconButton(
                        icon: Icons.notifications_none_rounded,
                        badgeCount: unread,
                        onTap: () => _openNotifications(context),
                      ),
                      _HeaderIconButton(
                        icon: Icons.shopping_bag_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(context, AppPageRoutes.cart());
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    HapticFeedback.selectionClick();
    FloatingCartSuppression.acquire();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NotificationsSheet(),
    ).whenComplete(FloatingCartSuppression.release);
  }

  @override
  bool shouldRebuild(covariant HomeStickyDeliveryHeaderDelegate oldDelegate) =>
      oldDelegate.gutter != gutter;
}

class _ArrowPulse extends StatefulWidget {
  @override
  State<_ArrowPulse> createState() => _ArrowPulseState();
}

class _ArrowPulseState extends State<_ArrowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, 1.5 * _c.value),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: AppColor.primary.withValues(alpha: 0.65 + 0.35 * _c.value),
          ),
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Material(
        color: AppSurface.of(context).subtle.withValues(alpha: 0.65),
        shape: CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 22, color: AppSurface.of(context).textPrimary),
                if (badgeCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppSurface.of(context).danger,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsSheet extends ConsumerStatefulWidget {
  const _NotificationsSheet();

  @override
  ConsumerState<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState extends ConsumerState<_NotificationsSheet> {
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null || uid.isEmpty || _markingAll) return;
    setState(() => _markingAll = true);
    HapticFeedback.lightImpact();
    try {
      await ref.read(realtimeNotificationRepositoryProvider).markAllAsRead(uid);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsStreamProvider);
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unread = unreadAsync.when(
      data: (n) => n,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      TextButton(
                        onPressed: _markingAll ? null : _markAllRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: _markingAll
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColor.primary,
                                ),
                              )
                            : Text(
                                context.l10n.mark_all_read,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.primary,
                                ),
                              ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Text(
                      'Could not load notifications',
                      style: GoogleFonts.poppins(color: AppSurface.of(context).textMuted),
                    ),
                  ),
                  data: (items) {
                    final emptyFooter = items.isEmpty ? 1 : 0;
                    return ListView.builder(
                      controller: scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: 1 + items.length + emptyFooter,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _DeliveryLiveNotificationsCard(ref: ref);
                        }
                        if (items.isEmpty && i == 1) {
                          return Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Center(
                              child: Text(
                                'You\'re all caught up.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppSurface.of(context).textMuted,
                                ),
                              ),
                            ),
                          );
                        }
                        return _NotificationTile(
                          item: items[i - 1],
                          sheetContext: context,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Live delivery policy pulled from the same Firestore stream as cart pricing.
class _DeliveryLiveNotificationsCard extends StatelessWidget {
  const _DeliveryLiveNotificationsCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pricingConfigProvider);
    return async.when(
      loading: () => SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (config) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: AppColor.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery (live)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppSurface.of(context).textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    DeliveryPricingPolicy.notificationLiveLine(config),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppSurface.of(context).textSecondary,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    DeliveryPricingPolicy.offersLine(config),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: AppSurface.of(context).textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({
    required this.item,
    required this.sheetContext,
  });

  final NotificationItem item;
  final BuildContext sheetContext;

  Future<void> _onTap(WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid != null && uid.isNotEmpty && !item.read) {
      await ref
          .read(realtimeNotificationRepositoryProvider)
          .markAsRead(uid, item.id);
    }

    if (!sheetContext.mounted) return;
    Navigator.pop(sheetContext);

    final root = rootNavigatorKey.currentContext;
    if (root == null || !root.mounted) return;
    await handlePushNavigation(notificationPushData(item));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !item.read;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Material(
        color: unread
            ? AppColor.primary.withValues(alpha: 0.1)
            : AppSurface.of(context).subtle.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _onTap(ref),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unread) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      color: AppSurface.of(context).danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty ? 'Update' : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight:
                              unread ? FontWeight.w800 : FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      if (item.body.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          item.body,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppSurface.of(context).textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppSurface.of(context).textMuted.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
