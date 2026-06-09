import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/maintenance/domain/maintenance_status.dart';
import 'package:quickgrocery/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:quickgrocery/maintenance/presentation/widgets/maintenance_countdown.dart';
import 'package:quickgrocery/maintenance/presentation/widgets/maintenance_engagement_section.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Premium maintenance UI — Blinkit/Zomato-inspired gradient + Lottie.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({
    super.key,
    required this.status,
    this.onRetry,
  });

  final MaintenanceStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(maintenanceRefreshProvider);
    final locale = Localizations.localeOf(context).toString();
    final config = status.config;
    final isDark = config.theme == 'dark';
    final reopen = status.effectiveReopen ?? config.reopenTime;

    final gradient = isDark
        ? const [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF16213E)]
        : [
            AppColor.primary.withValues(alpha: 0.95),
            const Color(0xFFFFB347),
            const Color(0xFFFFF8E7),
          ];

    final fg = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(maintenanceConfigStreamProvider);
              ref.invalidate(maintenanceStatusProvider);
              onRetry?.call();
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _LogoPulse(),
                  const SizedBox(height: 20),
                  if (config.bannerImageUrl.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: config.bannerImageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (config.lottieUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: Lottie.network(config.lottieUrl),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 140,
                      child: Lottie.asset(
                        'assets/lottie/no_data.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    config.title.forLocale(locale),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    config.subtitle.forLocale(locale),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: fg.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    config.message.forLocale(locale),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                      color: fg.withValues(alpha: 0.75),
                    ),
                  ),
                  if (reopen != null && reopen.isAfter(DateTime.now())) ...[
                    const SizedBox(height: 28),
                    MaintenanceCountdown(
                      target: reopen,
                      textColor: fg,
                    ),
                  ],
                  const SizedBox(height: 28),
                  _ConnectivityBanner(fg: fg),
                  const SizedBox(height: 16),
                  if (config.showRetryButton)
                    _ActionButton(
                      label: context.l10n.maintenance_retry,
                      icon: Icons.refresh_rounded,
                      onPressed: () {
                        ref.invalidate(maintenanceConfigStreamProvider);
                        onRetry?.call();
                      },
                      filled: true,
                      fg: fg,
                    ),
                  if (config.showSupportButton) ...[
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: context.l10n.maintenance_contact_support,
                      icon: Icons.support_agent_rounded,
                      onPressed: () => _contactSupport(config.supportPhone, config.supportEmail),
                      filled: false,
                      fg: fg,
                    ),
                  ],
                  if (config.socialLinks.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SocialRow(links: config.socialLinks, fg: fg),
                  ],
                  const SizedBox(height: 24),
                  MaintenanceEngagementSection(
                    engagement: config.engagement,
                    locale: locale,
                    textColor: fg,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _contactSupport(String phone, String email) async {
    if (phone.trim().isNotEmpty) {
      final uri = Uri.parse('tel:${phone.trim()}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (email.trim().isNotEmpty) {
      final uri = Uri.parse('mailto:${email.trim()}');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }
}

class _LogoPulse extends StatefulWidget {
  @override
  State<_LogoPulse> createState() => _LogoPulseState();
}

class _LogoPulseState extends State<_LogoPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          Icons.storefront_rounded,
          size: 44,
          color: AppColor.primary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    required this.fg,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: fg),
              label: Text(label, style: TextStyle(color: fg)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: fg.withValues(alpha: 0.5)),
              ),
            ),
    );
  }
}

class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner({required this.fg});
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectivityProvider).valueOrNull ?? [];
    final offline = conn.isEmpty ||
        conn.every((r) => r == ConnectivityResult.none);
    if (!offline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.maintenance_offline,
              style: GoogleFonts.poppins(fontSize: 13, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.links, required this.fg});
  final Map<String, String> links;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      alignment: WrapAlignment.center,
      children: links.entries
          .where((e) => e.value.trim().isNotEmpty)
          .map(
            (e) => ActionChip(
              label: Text(e.key),
              onPressed: () async {
                final uri = Uri.tryParse(e.value);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          )
          .toList(),
    );
  }
}
