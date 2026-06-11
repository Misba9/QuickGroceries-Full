import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/orders/presentation/providers/orders_providers.dart';
import 'package:quickgrocery/view/cart/presentation/providers/coupons_provider.dart';
import 'package:quickgrocery/view/profile/domain/profile_models.dart';
import 'package:quickgrocery/view/profile/presentation/providers/profile_providers.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_section_safe.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/guest_profile_view.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_sections.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Premium Blinkit/Zepto-style account dashboard.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _appVersion = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      legacy.Provider.of<HomeProvider>(context, listen: false).getCustomer();
    });
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final home = legacy.Provider.of<HomeProvider>(context, listen: false);
    home.customer = null;
    ref.invalidate(customerProfileStreamProvider);
    ref.invalidate(userOrdersStreamProvider);
    ref.invalidate(wishlistCountProvider);
    ref.invalidate(addressCountProvider);
    ref.invalidate(couponsStreamProvider);
    await home.getCustomer();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  ProfileData? _resolveProfile(ProfileData? streamProfile) {
    if (streamProfile != null) return streamProfile;
    final c = legacy.Provider.of<HomeProvider>(context, listen: false).customer;
    if (c == null) return null;
    return ProfileData(
      customer: c,
      walletBalance: 0,
      rewardPoints: 0,
      cashbackEarned: 0,
      referralEarnings: 0,
      isPremiumMember: false,
      referralCode: c.id,
      gender: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(isGuestModeProvider)) {
      return const GuestProfileView();
    }

    final profileAsync = ref.watch(customerProfileStreamProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        legacy.Provider.of<HomeProvider>(context, listen: false)
            .onSelectedChange(0);
      },
      child: Scaffold(
        backgroundColor: AppSurface.background,
        body: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            final resolved = _resolveProfile(profile);
            if (resolved == null) {
              return Center(child: Text(context.l10n.profile));
            }

            return RefreshIndicator(
              color: AppSurface.text,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeaderSection(profile: resolved),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ProfileSectionGuard(
                          section: 'Quick Actions',
                          builder: () => const ProfileQuickActions(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Active Order',
                          builder: () => const ProfileActiveOrderCard(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'My Orders',
                          builder: () => const ProfileOrdersSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Addresses',
                          builder: () => const ProfileAddressesSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Saved Coupons',
                          builder: () => const ProfileSavedCouponsSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Refer & Earn',
                          builder: () => const ProfileReferEarnSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Partner with us',
                          builder: () => const ProfilePartnerSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Notifications',
                          builder: () => const ProfileNotificationsSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Language',
                          builder: () => const ProfileLanguageSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Support',
                          builder: () => const ProfileSupportSection(),
                        ),
                        const SizedBox(height: 16),
                        ProfileSectionGuard(
                          section: 'Legal',
                          builder: () =>
                              ProfileLegalSection(appVersion: _appVersion),
                        ),
                        const SizedBox(height: 20),
                        ProfileSectionGuard(
                          section: 'Logout',
                          builder: () => const ProfileLogoutSection(),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Legacy list tile used by older screens.
class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 25,
          width: 25,
          child: Image.asset(icon, color: AppSurface.text),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
