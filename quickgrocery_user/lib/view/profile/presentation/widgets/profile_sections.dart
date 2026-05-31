import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/services/language_service.dart';
import 'package:quickgrocery/view/address/screens/address_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
import 'package:quickgrocery/view/notifications/notification_center_screen.dart';
import 'package:quickgrocery/view/orders/domain/order_models.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/orders/presentation/screens/order_tracking_screen.dart';
import 'package:quickgrocery/view/profile/domain/profile_models.dart';
import 'package:quickgrocery/view/profile/presentation/providers/profile_providers.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_ui.dart';
import 'package:quickgrocery/view/profile/screens/edit_profile_screen.dart';
import 'package:quickgrocery/view/profile/screens/support_screen.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/cart/data/coupon_service.dart';
import 'package:quickgrocery/view/coupons/coupon_screen.dart';
import 'package:quickgrocery/view/support/presentation/providers/support_settings_providers.dart';
import 'package:quickgrocery/view/support/services/support_action_launcher.dart';
import 'package:quickgrocery/view/wishlist/screens/wishlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openProfileUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

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
              c.name.isNotEmpty ? c.name : 'guest'.tr(),
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
                  'complete_profile'.tr(),
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
                  'edit_profile'.tr(),
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
              label: 'quick_orders'.tr(),
              value: '${orderCounts?.total ?? 0}',
              onTap: () => _goOrders(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.favorite_border_rounded,
              label: 'quick_wishlist'.tr(),
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
              label: 'quick_address'.tr(),
              value: '$addressCount',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen()),
              ),
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
                  'live_order_tracking'.tr(),
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
                  'track_order'.tr(),
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
      case OrderStatus.pending:
        return 0.15;
      case OrderStatus.accepted:
        return 0.35;
      case OrderStatus.packing:
        return 0.55;
      case OrderStatus.outForDelivery:
        return 0.85;
      default:
        return 0.2;
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
            title: 'my_orders'.tr(),
            actionLabel: 'view_all_arrow'.tr(),
            onAction: () => legacy.Provider.of<HomeProvider>(context,
                    listen: false)
                .onSelectedChange(3),
          ),
          ProfileCard(
            child: Column(
              children: [
                ProfileListTile(
                  icon: Icons.hourglass_top_rounded,
                  title: '${'pending_orders'.tr()} (${counts.pending})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: '${'delivered_orders'.tr()} (${counts.delivered})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.cancel_outlined,
                  title: '${'cancelled_orders'.tr()} (${counts.cancelled})',
                  onTap: () => legacy.Provider.of<HomeProvider>(context,
                          listen: false)
                      .onSelectedChange(3),
                ),
                ProfileListTile(
                  icon: Icons.undo_rounded,
                  title: '${'returned_orders'.tr()} (${counts.returned})',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ?? 'coupon_applied_checkout'.tr(namedArgs: {'code': coupon.code}),
        ),
        backgroundColor: err == null ? Colors.green.shade700 : Colors.red,
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('coupon_copied'.tr(namedArgs: {'code': code}))),
    );
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
            loading: () => ProfileSectionTitle(title: 'saved_coupons'.tr()),
            error: (_, __) => ProfileSectionTitle(title: 'saved_coupons'.tr()),
            data: (coupons) => ProfileSectionTitle(
              title: 'saved_coupons'.tr(),
              actionLabel: coupons.isEmpty
                  ? null
                  : 'coupons_available'.tr(namedArgs: {
                      'count': '${coupons.length}',
                    }),
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
                'could_not_load_coupons'.tr(),
                style: GoogleFonts.poppins(color: AppSurface.textMuted),
              ),
              data: (coupons) {
                if (coupons.isEmpty) {
                  return Text(
                    'no_saved_coupons'.tr(),
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
                      'apply'.tr(),
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
            title: 'saved_addresses'.tr(),
            actionLabel: 'manage_arrow'.tr(),
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressScreen()),
            ),
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
                    title: 'add_first_address'.tr(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddressScreen(),
                      ),
                    ),
                  );
                }
                return Column(
                  children: addresses.take(3).map((a) {
                    return ProfileListTile(
                      icon: addressTypeIcon(a.type),
                      title: a.type.isNotEmpty ? a.type : 'Address',
                      subtitle: '${a.address}, ${a.area}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddressScreen(),
                        ),
                      ),
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

// ─── Notifications ────────────────────────────────────────────────────────

class ProfileNotificationsSection extends ConsumerWidget {
  const ProfileNotificationsSection({super.key, this.animationIndex = 9});

  final int animationIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(
            title: 'notifications'.tr(),
            actionLabel: 'inbox'.tr(),
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            ),
          ),
          ProfileCard(
            child: Column(
              children: [
                ProfileToggleTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'order_updates'.tr(),
                  value: prefs.orderUpdates,
                  onChanged: (v) => notifier.toggle('orderUpdates', v),
                ),
                ProfileToggleTile(
                  icon: Icons.local_offer_outlined,
                  title: 'offers_discounts'.tr(),
                  value: prefs.offersDiscounts,
                  onChanged: (v) => notifier.toggle('offersDiscounts', v),
                ),
                ProfileToggleTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'product_alerts'.tr(),
                  value: prefs.productAlerts,
                  onChanged: (v) => notifier.toggle('productAlerts', v),
                ),
                ProfileToggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'promotional_messages'.tr(),
                  value: prefs.promotionalMessages,
                  onChanged: (v) => notifier.toggle('promotionalMessages', v),
                ),
                ProfileToggleTile(
                  icon: Icons.delivery_dining_outlined,
                  title: 'delivery_notifications'.tr(),
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
          ProfileSectionTitle(title: 'language'.tr()),
          legacy.Consumer<LanguageService>(
            builder: (context, languageService, _) {
              final current = context.locale;
              return ProfileCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languageService.getAvailableLanguages().map((lang) {
                    final isSelected = current.languageCode == lang['code'] &&
                        current.countryCode == lang['country'];
                    return AnimatedContainer(
                      duration: AppMotion.short,
                      curve: AppMotion.standard,
                      child: Material(
                        color: isSelected
                            ? AppColor.primary.withValues(alpha: 0.15)
                            : AppSurface.subtle,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => languageService.changeLanguage(
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

    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: 'support'.tr()),
          ProfileCard(
            child: settingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => Column(
                children: [
                  ProfileListTile(
                    icon: Icons.call_outlined,
                    title: 'call_support'.tr(),
                    subtitle: '90242-83577',
                    onTap: () =>
                        SupportActionLauncher.callPhone(context, '9024283577'),
                  ),
                  ProfileListTile(
                    icon: Icons.email_outlined,
                    title: 'email_support'.tr(),
                    onTap: () => SupportActionLauncher.sendEmail(
                      context,
                      'support@quickgrocery.io',
                    ),
                  ),
                  ProfileListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'faq'.tr(),
                    onTap: () => _openProfileUrl('https://quickgrocery.io/about'),
                  ),
                ],
              ),
              data: (settings) => Column(
                children: [
                  if (settings.hasPhone)
                    ProfileListTile(
                      icon: Icons.call_outlined,
                      title: 'call_support'.tr(),
                      subtitle: settings.phone,
                      onTap: () => SupportActionLauncher.callPhone(
                        context,
                        settings.phone,
                      ),
                    ),
                  if (settings.hasEmail)
                    ProfileListTile(
                      icon: Icons.email_outlined,
                      title: 'email_support'.tr(),
                      subtitle: settings.email,
                      onTap: () => SupportActionLauncher.sendEmail(
                        context,
                        settings.email,
                      ),
                    ),
                  ProfileListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'faq'.tr(),
                    onTap: () => _openProfileUrl('https://quickgrocery.io/about'),
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: 'legal'.tr()),
          ProfileCard(
            child: Column(
              children: [
                ...[
                  ('Privacy Policy', 'https://quickgrocery.io/privacy'),
                  ('Terms & Conditions', 'https://quickgrocery.io/terms'),
                  ('Refund Policy', 'https://quickgrocery.io/refund'),
                  ('Shipping Policy', 'https://quickgrocery.io/shipping'),
                  ('About Us', 'https://quickgrocery.io/about'),
                ].map(
                  (e) => ProfileListTile(
                    icon: Icons.description_outlined,
                    title: e.$1,
                    onTap: () => _openProfileUrl(e.$2),
                  ),
                ),
                ProfileListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'app_version'.tr(),
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

// ─── App settings ─────────────────────────────────────────────────────────

class ProfileAppSettingsSection extends StatefulWidget {
  const ProfileAppSettingsSection({super.key, this.animationIndex = 14});

  final int animationIndex;

  @override
  State<ProfileAppSettingsSection> createState() =>
      _ProfileAppSettingsSectionState();
}

class _ProfileAppSettingsSectionState extends State<ProfileAppSettingsSection> {
  bool _darkMode = false;
  bool _biometric = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pref = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _darkMode = pref.getBool('dark_mode') ?? false;
      _biometric = pref.getBool('biometric_login') ?? false;
    });
  }

  Future<void> _setPref(String key, bool value) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + widget.animationIndex * 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileSectionTitle(title: 'app_settings'.tr()),
          ProfileCard(
            child: Column(
              children: [
                ProfileToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'dark_mode'.tr(),
                  value: _darkMode,
                  onChanged: (v) async {
                    setState(() => _darkMode = v);
                    await _setPref('dark_mode', v);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Dark mode preference saved (app-wide theme coming soon)',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ProfileToggleTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'biometric_login'.tr(),
                  value: _biometric,
                  onChanged: (v) async {
                    setState(() => _biometric = v);
                    await _setPref('biometric_login', v);
                  },
                ),
                ProfileListTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'clear_cache'.tr(),
                  onTap: () async {
                    final pref = await SharedPreferences.getInstance();
                    final keys = pref.getKeys().where(
                          (k) => k.startsWith('cache_'),
                        );
                    for (final k in keys) {
                      await pref.remove(k);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    }
                  },
                ),
                ProfileListTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'delete_account'.tr(),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete account?'),
                      content: const Text(
                        'Please contact support to permanently delete your account.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupportScreen(),
                              ),
                            );
                          },
                          child: const Text('Contact Support'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logout ───────────────────────────────────────────────────────────────

class ProfileLogoutSection extends StatelessWidget {
  const ProfileLogoutSection({super.key, this.animationIndex = 15});

  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: Duration(milliseconds: 380 + animationIndex * 40),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: Text(
            'logout'.tr(),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
