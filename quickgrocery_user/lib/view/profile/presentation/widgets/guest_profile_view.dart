import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/auth/guest_auth_guard.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/profile/presentation/widgets/profile_sections.dart';

/// Profile tab content for unauthenticated guest browsing.
class GuestProfileView extends ConsumerWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        legacy.Provider.of<HomeProvider>(context, listen: false)
            .onSelectedChange(0);
      },
      child: Scaffold(
        backgroundColor: AppSurface.of(context).background,
        body: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 28),
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
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.black.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 44,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.guestProfileTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.guestProfileSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () =>
                            GuestAuthGuard.requireAuth(context, ref),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          context.l10n.loginAction,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const ProfileAppUpdateSection(),
                  const ProfileAppearanceSection(),
                  const SizedBox(height: 16),
                  const ProfileLanguageSection(),
                  const SizedBox(height: 16),
                  const ProfileSupportSection(),
                  const SizedBox(height: 16),
                  ProfileLegalSection(appVersion: '—'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
