import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/account/account_deletion_exception.dart';
import 'package:quickgrocery/core/account/account_deletion_reauth.dart';
import 'package:quickgrocery/core/account/account_deletion_service.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/locale_provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/auth/auth_session_manager.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/profile/domain/profile_models.dart';
import 'package:quickgrocery/view/profile/presentation/providers/profile_providers.dart';
import 'package:quickgrocery/core/permissions/app_permission_coordinator.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_ui.dart';
import 'package:quickgrocery/view/profile/screens/edit_profile_screen.dart';
import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/coupons/coupon_screen.dart';
import 'package:quickgrocery/view/profile/presentation/utils/profile_url_opener.dart';
import 'package:quickgrocery/view/support/models/support_settings.dart';
import 'package:quickgrocery/view/support/presentation/providers/support_settings_provider.dart';
import 'package:quickgrocery/view/support/services/support_action_launcher.dart';
import 'package:quickgrocery/view/refer/screens/refer_screen.dart';
import 'package:quickgrocery/view/wishlist/screens/wishlist_screen.dart';

// ─── Header ───────────────────────────────────────────────────────────────

class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({
    super.key,
    required this.profile,
    this.animationIndex = 0,
  });

  final ProfileData profile;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final c = profile.customer;
    final completion = profile.profileCompletionPercent;

    return FadeInDown(
      duration: Duration(milliseconds: 420 + animationIndex * 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColor.primary.withValues(alpha: 0.95),
              Color.lerp(AppColor.primary, Colors.orange, 0.35)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          boxShadow: AppShadow.primaryGlow,
        ),
        child: Column(
          children: [
            _ProfileAvatar(
              imageUrl: c.image,
              gender: profile.gender,
              name: c.name,
            ),
            const SizedBox(height: 14),
            Text(
              c.name.isNotEmpty ? c.name : context.l10n.guest,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            if (c.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 6),
              _HeaderInfoRow(
                icon: Icons.phone_rounded,
                text: c.phoneNumber.startsWith('+')
                    ? c.phoneNumber
                    : '+91 ${c.phoneNumber}',
              ),
            ],
            if (c.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              _HeaderInfoRow(icon: Icons.email_outlined, text: c.email),
            ],
            const SizedBox(height: 16),
            if (completion < 100) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.complete_profile,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.35),
                  color: Colors.black87,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$completion%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black54),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  context.l10n.edit_profile,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.gender,
    required this.name,
  });

  final String imageUrl;
  final String gender;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: AppShadow.raised,
      ),
      child: CircleAvatar(
        radius: 46,
        backgroundColor: Colors.white,
        backgroundImage:
            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Image.asset(
                gender == 'female'
                    ? 'assets/icons/woman.png'
                    : 'assets/icons/man.png',
                width: 56,
                height: 56,
              )
            : null,
      ),
    );
  }
}

class _HeaderInfoRow extends StatelessWidget {
  const _HeaderInfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────

class ProfileQuickActions extends ConsumerWidget {
  const ProfileQuickActions({super.key, this.animationIndex = 1});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderCounts = ref.watch(orderCountsProvider).valueOrNull;
    final wishlistCount = ref.watch(wishlistCountProvider).valueOrNull ?? 0;
    final addressCount = ref.watch(addressCountProvider).valueOrNull ?? 0;

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.receipt_long_rounded,
              label: context.l10n.quick_orders,
              value: '${orderCounts?.total ?? 0}',
              onTap: () => _goOrders(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.favorite_border_rounded,
              label: context.l10n.quick_wishlist,
              value: '$wishlistCount',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WishlistScreen()),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.location_on_outlined,
              label: context.l10n.quick_address,
              value: '$addressCount',
              onTap: () => Navigator.push(context, AppPageRoutes.address()),
            ),
          ),
        ],
      ),
    );
  }

  void _goOrders(BuildContext context) {
    legacy.Provider.of<HomeProvider>(context, listen: false)
        .onSelectedChange(3);
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        splashColor: AppColor.primary.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppSurface.border),
            boxShadow: AppShadow.card,
          ),
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColor.primary, size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppSurface.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active order ─────────────────────────────────────────────────────────

class ProfileActiveOrderCard extends ConsumerWidget {
  const ProfileActiveOrderCard({super.key, this.animationIndex = 2});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activeOrderProvider);
    if (order == null) return const SizedBox.shrink();

    final eta = ref.watch(etaProvider(order.id));
    final etaMin = (eta.inSeconds / 60).round().clamp(1, 90);
    final progress = _statusProgress(order);

    return FadeInUp(
      duration: Duration(milliseconds: 400 + animationIndex * 40),
      child: ProfileCard(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_rounded,
                    color: AppColor.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.live_order_tracking,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Order #${order.shortOrderId}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.status.displayName,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ETA · $etaMin mins',
              style: GoogleFonts.poppins(
                color: AppColor.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                duration: AppMotion.medium,
                tween: Tween(begin: 0, end: progress),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: AppColor.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderTrackingScreen(orderId: order.id),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.track_order,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _statusProgress(LiveOrder order) {
    if (order.isDelivered) return 1;
    switch (order.status) {
      case OrderStatus.orderPlaced:
        return 0.2;
      case OrderStatus.deliveryAssigned:
        return 0.5;
      case OrderStatus.outForDelivery:
        return 0.85;
      case OrderStatus.delivered:
        return 1;
      default:
        return 0.15;
    }
  }
}

// ─── My orders ────────────────────────────────────────────────────────────

class ProfileOrdersSection extends ConsumerWidget {
  const ProfileOrdersSection({super.key, this.animationIndex = 3});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(orderCountsProvider).valueOrNull ??
        const OrderCounts(
          pending: 0,
          delivered: 0,
          cancelled: 0,
          returned: 0,
        );

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(
            title: context.l10n.my_orders,
            actionLabel: context.l10n.view_all_arrow,
            onAction: () => legacy.Provider.of<HomeProvider>(context,
                    listen: false)
                .onSelectedChange(3),
          ),
          ProfileCard(
            child: Column(
              children: [
                ProfileListTile(
                  icon: Icons.hourglass_top_rounded,
                  title: '${context.l10n.pending_orders} (${counts.pending})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: '${context.l10n.delivered_orders} (${counts.delivered})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.cancel_outlined,
                  title: '${context.l10n.cancelled_orders} (${counts.cancelled})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.undo_rounded,
                  title: '${context.l10n.returned_orders} (${counts.returned})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Saved coupons ────────────────────────────────────────────────────────

class ProfileSavedCouponsSection extends ConsumerStatefulWidget {
  const ProfileSavedCouponsSection({super.key, this.animationIndex = 5});

  final int animationIndex;

  @override
  ConsumerState<ProfileSavedCouponsSection> createState() =>
      _ProfileSavedCouponsSectionState();
}

class _ProfileSavedCouponsSectionState
    extends ConsumerState<ProfileSavedCouponsSection> {
  String? _applyingCode;

  Future<void> _applyCoupon(CouponEntry coupon) async {
    setState(() => _applyingCode = coupon.code);
    final phone = legacy.Provider.of<HomeProvider>(context, listen: false)
        .customer
        ?.phoneNumber;
    final err = await ref.read(cartProvider.notifier).applyCouponValidated(
          code: coupon.code,
          validationClient: ref.read(couponValidationClientProvider),
          phone: phone,
        );
    if (!mounted) return;
    setState(() => _applyingCode = null);
    if (err != null) {
      AppSnackBar.error(err, context: context);
    } else {
      AppSnackBar.success(
        context.l10n.coupon_applied_checkout(coupon.code),
        context: context,
      );
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppSnackBar.success(context.l10n.coupon_copied(code), context: context);
  }

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(couponsStreamProvider);

    return FadeInUp(
      duration: Duration(milliseconds: 380 + widget.animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          couponsAsync.when(
            loading: () => ProfileSectionTitle(title: context.l10n.saved_coupons),
            error: (_, __) => ProfileSectionTitle(title: context.l10n.saved_coupons),
            data: (coupons) => ProfileSectionTitle(
              title: context.l10n.saved_coupons,
              actionLabel: coupons.isEmpty
                  ? null
                  : context.l10n.coupons_available(coupons.length),
              onAction: coupons.isEmpty
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CouponScreen()),
                      ),
            ),
          ),
          ProfileCard(
            child: couponsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                context.l10n.could_not_load_coupons,
                style: GoogleFonts.poppins(color: AppSurface.textMuted),
              ),
              data: (coupons) {
                if (coupons.isEmpty) {
                  return Text(
                    context.l10n.no_saved_coupons,
                    style: GoogleFonts.poppins(
                      color: AppSurface.textMuted,
                      fontSize: 13,
                    ),
                  );
                }
                return Column(
                  children: coupons.take(5).map((coupon) {
                    final applying = _applyingCode == coupon.code;
                    return _SavedCouponCard(
                      coupon: coupon,
                      applying: applying,
                      onCopy: () => _copyCode(coupon.code),
                      onApply: () => _applyCoupon(coupon),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCouponCard extends StatelessWidget {
  const _SavedCouponCard({
    required this.coupon,
    required this.applying,
    required this.onCopy,
    required this.onApply,
  });

  final CouponEntry coupon;
  final bool applying;
  final VoidCallback onCopy;
  final VoidCallback onApply;

  String get _subtitle {
    if (coupon.description.isNotEmpty) return coupon.description;
    if (coupon.freeDelivery) return 'Free Delivery';
    if (coupon.flatAmount > 0) return 'Get ₹${coupon.flatAmount} OFF';
    if (coupon.discountPercent > 0) return '${coupon.discountPercent}% OFF';
    return 'Special offer';
  }

  String get _minOrderText {
    if (coupon.minOrderValue <= 0) return '';
    return 'Minimum order ₹${coupon.minOrderValue}';
  }

  String get _maxDiscountText {
    if (coupon.maxDiscountAmount <= 0) return '';
    return 'Maximum discount ₹${coupon.maxDiscountAmount}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppSurface.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Text(
                        coupon.code,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy_rounded,
                          size: 16, color: AppSurface.textMuted),
                    ],
                  ),
                ),
              ),
              if (coupon.isFirstOrderOffer)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'NEW',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (_minOrderText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              _minOrderText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.textMuted,
              ),
            ),
          ],
          if (_maxDiscountText.isNotEmpty)
            Text(
              _maxDiscountText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppSurface.textMuted,
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              onPressed: applying ? null : onApply,
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: applying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      context.l10n.apply,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Addresses ────────────────────────────────────────────────────────────

class ProfileAddressesSection extends ConsumerWidget {
  const ProfileAddressesSection({super.key, this.animationIndex = 7});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(userAddressesStreamProvider);

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(
            title: context.l10n.saved_addresses,
            actionLabel: context.l10n.manage_arrow,
            onAction: () => Navigator.push(context, AppPageRoutes.address()),
          ),
          ProfileCard(
            child: addressesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Text(
                'Could not load addresses',
                style: GoogleFonts.poppins(color: AppSurface.textMuted),
              ),
              data: (addresses) {
                if (addresses.isEmpty) {
                  return ProfileListTile(
                    icon: Icons.add_location_alt_outlined,
                    title: context.l10n.add_first_address,
                    onTap: () => Navigator.push(context, AppPageRoutes.address()),
                  );
                }
                return Column(
                  children: addresses.take(3).map((a) {
                    return ProfileListTile(
                      icon: addressTypeIcon(a.type),
                      title: a.type.isNotEmpty ? a.type : 'Address',
                      subtitle: '${a.address}, ${a.area}',
                      onTap: () => Navigator.push(context, AppPageRoutes.address()),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Partner with us ──────────────────────────────────────────────────────

class ProfilePartnerSection extends StatelessWidget {
  const ProfilePartnerSection({super.key, this.animationIndex = 9});

  static const partnerUrl = 'https://www.quickgroceries.in/PartnerWithUs';

  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: context.l10n.partner_with_us),
          ProfileCard(
            child: ProfileListTile(
              icon: Icons.storefront_outlined,
              title: context.l10n.become_store_partner,
              subtitle: context.l10n.partner_with_us_subtitle,
              onTap: () => openProfileUrl(
                context,
                url: partnerUrl,
                title: context.l10n.partner_with_us,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Refer & Earn ─────────────────────────────────────────────────────────

class ProfileReferEarnSection extends StatelessWidget {
  const ProfileReferEarnSection({super.key, this.animationIndex = 8});

  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: 'Refer & Earn'),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReferScreen(),
                ),
              ),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primary.withValues(alpha: 0.95),
                      Color.lerp(AppColor.primary, Colors.deepOrange, 0.4)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  boxShadow: AppShadow.primaryGlow,
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite Friends & Earn Rewards',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share your code · Earn up to ₹50 per friend',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Share',
                            style: GoogleFonts.poppins(
                              color: AppColor.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColor.primary,
                          ),
                        ],
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

// ─── Notifications ────────────────────────────────────────────────────────

class ProfileNotificationsSection extends ConsumerStatefulWidget {
  const ProfileNotificationsSection({super.key, this.animationIndex = 9});

  final int animationIndex;

  @override
  ConsumerState<ProfileNotificationsSection> createState() =>
      _ProfileNotificationsSectionState();
}

class _ProfileNotificationsSectionState
    extends ConsumerState<ProfileNotificationsSection> {
  bool _showDeniedBanner = false;

  @override
  void initState() {
    super.initState();
    AppPermissionCoordinator.shouldShowNotificationDeniedBanner().then((v) {
      if (mounted) setState(() => _showDeniedBanner = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return FadeInUp(
      duration: Duration(milliseconds: 380 + widget.animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(
            title: context.l10n.notifications,
            actionLabel: context.l10n.inbox,
            onAction: () => Navigator.push(context, AppPageRoutes.notifications()),
          ),
          if (_showDeniedBanner) ...[
            Material(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.notifications_off_outlined,
                    color: Colors.orange.shade800),
                title: Text(
                  'Enable notifications in system settings for order alerts.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    await AppPermissionCoordinator
                        .markNotificationDeniedBannerShown();
                    if (mounted) setState(() => _showDeniedBanner = false);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          ProfileCard(
            child: Column(
              children: [
                ProfileToggleTile(
                  icon: Icons.local_shipping_outlined,
                  title: context.l10n.order_updates,
                  value: prefs.orderUpdates,
                  onChanged: (v) => notifier.toggle('orderUpdates', v),
                ),
                ProfileToggleTile(
                  icon: Icons.local_offer_outlined,
                  title: context.l10n.offers_discounts,
                  value: prefs.offersDiscounts,
                  onChanged: (v) => notifier.toggle('offersDiscounts', v),
                ),
                ProfileToggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: context.l10n.product_alerts,
                  value: prefs.productAlerts,
                  onChanged: (v) => notifier.toggle('productAlerts', v),
                ),
                ProfileToggleTile(
                  icon: Icons.campaign_outlined,
                  title: context.l10n.promotional_messages,
                  value: prefs.promotionalMessages,
                  onChanged: (v) => notifier.toggle('promotionalMessages', v),
                ),
                ProfileToggleTile(
                  icon: Icons.delivery_dining_outlined,
                  title: context.l10n.delivery_notifications,
                  value: prefs.deliveryNotifications,
                  onChanged: (v) => notifier.toggle('deliveryNotifications', v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language ─────────────────────────────────────────────────────────────

class ProfileLanguageSection extends StatelessWidget {
  const ProfileLanguageSection({super.key, this.animationIndex = 10});

  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: context.l10n.language),
          Consumer(
            builder: (context, ref, _) {
              final locale = ref.watch(localeProvider);
              final controller = ref.read(localeProvider.notifier);
              return ProfileCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.availableLanguages.map((lang) {
                    final isSelected =
                        locale.languageCode == lang['code'];
                    return AnimatedContainer(
                      duration: AppMotion.short,
                      curve: AppMotion.standard,
                      child: Material(
                        color: isSelected
                            ? AppColor.primary.withValues(alpha: 0.15)
                            : AppSurface.subtle,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => controller.setLocale(
                            Locale(
                              lang['code'] as String,
                              lang['country'] as String,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColor.primary
                                    : AppSurface.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              lang['name'] as String,
                              style: GoogleFonts.poppins(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColor.primary
                                    : AppSurface.text,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Support ──────────────────────────────────────────────────────────────

class ProfileSupportSection extends ConsumerWidget {
  const ProfileSupportSection({super.key, this.animationIndex = 12});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(supportSettingsStreamProvider);
    final settings = settingsAsync.value ?? SupportSettings.defaults;

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: context.l10n.support),
          ProfileCard(
            child: Column(
              children: [
                if (settings.hasPhone)
                  ProfileListTile(
                    icon: Icons.call_outlined,
                    title: context.l10n.call_support,
                    subtitle: settings.phone,
                    onTap: () =>
                        SupportActionLauncher.callPhone(context, settings.phone),
                  ),
                if (settings.hasEmail)
                  ProfileListTile(
                    icon: Icons.email_outlined,
                    title: context.l10n.email_support,
                    subtitle: settings.email,
                    onTap: () =>
                        SupportActionLauncher.sendEmail(context, settings.email),
                  ),
                if (settings.hasWhatsapp || settings.hasPhone)
                  ProfileListTile(
                    icon: Icons.chat_outlined,
                    title: context.l10n.whatsapp_support,
                    subtitle: settings.whatsappLaunch,
                    onTap: () => SupportActionLauncher.openWhatsApp(
                      context,
                      settings.whatsappLaunch,
                    ),
                  ),
                if (settings.hasMessage) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      settings.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppSurface.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legal ────────────────────────────────────────────────────────────────

class ProfileLegalSection extends StatelessWidget {
  const ProfileLegalSection({
    super.key,
    required this.appVersion,
    this.animationIndex = 13,
  });

  final String appVersion;
  final int animationIndex;

  static const _legalPages = <({String title, String url, IconData icon})>[
    (
      title: 'Safety',
      url: 'https://www.quickgroceries.in/safety',
      icon: Icons.shield_outlined,
    ),
    (
      title: 'Terms & Conditions',
      url: 'https://www.quickgroceries.in/terms',
      icon: Icons.description_outlined,
    ),
    (
      title: 'Privacy Policy',
      url: 'https://www.quickgroceries.in/privacy',
      icon: Icons.privacy_tip_outlined,
    ),
    (
      title: 'About Us',
      url: 'https://www.quickgroceries.in/about',
      icon: Icons.info_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: context.l10n.legal),
          ProfileCard(
            child: Column(
              children: [
                ..._legalPages.map(
                  (page) => ProfileListTile(
                    icon: page.icon,
                    title: page.title,
                    onTap: () => openProfileUrl(
                      context,
                      url: page.url,
                      title: page.title,
                    ),
                  ),
                ),
                ProfileListTile(
                  icon: Icons.smartphone_outlined,
                  title: context.l10n.app_version,
                  subtitle: appVersion,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delete Account (Apple Guideline 5.1.1(v)) ────────────────────────────

class ProfileDeleteAccountSection extends ConsumerWidget {
  const ProfileDeleteAccountSection({super.key, this.animationIndex = 14});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Semantics(
        button: true,
        label: context.l10n.delete_account,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _confirmAndDeleteAccount(context, ref),
            icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade700),
            label: Text(
              context.l10n.delete_account,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Colors.red.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(48, 48),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete_account_title),
        content: Text(l10n.delete_account_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.delete_account),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await _runAccountDeletion(context, ref);
  }

  Future<void> _runAccountDeletion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackBar.error(l10n.delete_account_failed, context: context);
      return;
    }
    final uid = user.uid;

    // Reauth BEFORE wiping data so canceling OTP cannot leave a half-deleted account.
    final reauthed = await showAccountDeletionReauthSheet(context);
    if (!reauthed || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Material(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      l10n.delete_account_in_progress,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
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

    var loadingStillOpen = true;
    void dismissLoadingIfNeeded() {
      if (!loadingStillOpen || !context.mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
      loadingStillOpen = false;
    }

    final service = AccountDeletionService();

    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current == null || current.uid != uid) {
        throw AccountDeletionException(AccountDeletionErrorKind.notSignedIn);
      }

      await service.deleteUserOwnedData(uid);

      try {
        await service.deleteAuthUser();
      } on AccountDeletionException catch (e) {
        if (e.kind != AccountDeletionErrorKind.requiresRecentLogin) rethrow;
        // Rare: session aged during long data wipe — reauth once more.
        dismissLoadingIfNeeded();
        if (!context.mounted) {
          throw AccountDeletionException(AccountDeletionErrorKind.cancelled);
        }
        final again = await showAccountDeletionReauthSheet(context);
        if (!again) {
          throw AccountDeletionException(AccountDeletionErrorKind.cancelled);
        }
        if (!context.mounted) {
          throw AccountDeletionException(AccountDeletionErrorKind.cancelled);
        }
        loadingStillOpen = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        );
        await service.deleteAuthUser();
      }

      if (!context.mounted) return;
      final successMessage = l10n.delete_account_success;
      await AuthSessionManager.finalizeAfterAccountDeletion(
        context: context,
        ref: ref,
      );
      loadingStillOpen = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        AppSnackBar.success(successMessage, context: ctx);
      });
    } catch (e) {
      dismissLoadingIfNeeded();
      if (!context.mounted) return;
      if (e is AccountDeletionException &&
          e.kind == AccountDeletionErrorKind.cancelled) {
        return;
      }
      AppSnackBar.error(
        accountDeletionErrorMessage(context, e),
        context: context,
      );
    }
  }
}

// ─── Logout ───────────────────────────────────────────────────────────────

class ProfileLogoutSection extends ConsumerWidget {
  const ProfileLogoutSection({super.key, this.animationIndex = 15});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmLogout(context, ref),
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: Text(
            context.l10n.logout,
            style: GoogleFonts.poppins(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logoutTitle),
        content: Text(context.l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    // AuthSessionManager.popUntil(isFirst) already dismisses this dialog.
    // An unconditional finally-pop removed the MaterialApp root route on iOS
    // (child == null → SizedBox.shrink → black screen).
    var loadingStillOpen = true;
    void dismissLoadingIfNeeded() {
      if (!loadingStillOpen || !context.mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
      loadingStillOpen = false;
    }

    try {
      await AuthSessionManager.signOutFromContext(context: context, ref: ref);
      loadingStillOpen = false;
    } catch (e) {
      dismissLoadingIfNeeded();
      if (context.mounted) {
        AppSnackBar.error('Logout failed: $e', context: context);
      }
    }
  }
}
