import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/view/refer/services/refer_earn_service.dart';
import 'package:quickgrocery/view/refer/widgets/refer_share_actions.dart';
import 'package:share_plus/share_plus.dart';

/// Premium Refer & Earn experience (Zepto / Blinkit style).
class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen>
    with SingleTickerProviderStateMixin {
  final _service = ReferEarnService();
  ReferEarnDashboard _data = ReferEarnDashboard.fallback();
  ReferEarnLoadState _loadState = ReferEarnLoadState.comingSoon;
  bool _loading = true;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.loadDashboard();
    if (!mounted) return;
    setState(() {
      _data = result.data;
      _loadState = result.state;
      _loading = false;
    });
  }

  void _showShareDisabled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App download link not configured by Admin'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _copyCode() async {
    if (_data.referralCode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _data.referralCode));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied')),
    );
  }

  void _shareInvite() {
    if (!_data.canShare || _data.shareMessage.isEmpty) {
      _showShareDisabled();
      return;
    }
    Share.share(_data.shareMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurface.background,
      appBar: AppBar(
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppSurface.text,
        elevation: 0,
      ),
      body: _loading
          ? const _ReferLoadingState()
          : _loadState == ReferEarnLoadState.comingSoon
              ? _ReferComingSoonState(onRetry: _load)
              : _loadState == ReferEarnLoadState.unavailable
                  ? _ReferUnavailableState(onGoBack: () => Navigator.pop(context))
                  : _loadState == ReferEarnLoadState.networkError
                      ? _ReferNetworkErrorState(onRetry: _load)
                      : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _ReferHeaderBanner(
                          subtitle: _loadState == ReferEarnLoadState.partial
                              ? 'Limited mode — full rewards sync when server is ready.'
                              : 'Invite friends and earn rewards when they place their first order.',
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (_loadState == ReferEarnLoadState.partial)
                              _PartialDataBanner(),
                            if (!_data.canShare) _PlayStoreWarning(),
                            FadeInDown(
                              child: _ReferralCodeCard(
                                code: _data.referralCode,
                                pulse: _pulseCtrl,
                                onCopy: _copyCode,
                                onShare: _shareInvite,
                                canShare: _data.canShare,
                                onShareDisabled: _showShareDisabled,
                              ),
                            ),
                            AppSpacing.h15,
                            FadeInUp(
                              delay: const Duration(milliseconds: 80),
                              child: _RewardCard(data: _data),
                            ),
                            AppSpacing.h20,
                            FadeInUp(
                              delay: const Duration(milliseconds: 120),
                              child: _StatsSection(data: _data),
                            ),
                            AppSpacing.h20,
                            FadeInUp(
                              delay: const Duration(milliseconds: 160),
                              child: Text(
                                'Share invite',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            AppSpacing.h10,
                            ReferShareActions(
                              message: _data.shareMessage,
                              canShare: _data.canShare,
                              onNativeShare: _shareInvite,
                              onDisabledTap: _showShareDisabled,
                            ),
                            AppSpacing.h20,
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: _HistorySection(history: _data.history),
                            ),
                            AppSpacing.h20,
                            _TermsNote(data: _data),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ReferHeaderBanner extends StatelessWidget {
  const _ReferHeaderBanner({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary,
            Color.lerp(AppColor.primary, Colors.deepOrange, 0.45)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎁', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartialDataBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        'Showing saved referral info. Deploy Cloud Functions for live stats and rewards.',
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    );
  }
}

class _PlayStoreWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'App download link not configured by Admin',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({
    required this.code,
    required this.pulse,
    required this.onCopy,
    required this.onShare,
    required this.canShare,
    required this.onShareDisabled,
  });

  final String code;
  final AnimationController pulse;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final bool canShare;
  final VoidCallback onShareDisabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final glow = 0.15 + pulse.value * 0.12;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColor.primary,
                Color.lerp(AppColor.primary, Colors.orange, 0.4)!,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColor.primary.withValues(alpha: glow),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            'My Referral Code',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            code.isNotEmpty ? code : '—',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: code.isEmpty ? null : onCopy,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Code'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canShare ? onShare : onShareDisabled,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share Invite'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.data});

  final ReferEarnDashboard data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referral rewards',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          AppSpacing.h15,
          _RewardRow(
            label: 'You Get',
            value: '₹${data.referrerReward} Coupon',
            icon: Icons.card_giftcard,
            color: AppColor.primary,
          ),
          const SizedBox(height: 10),
          _RewardRow(
            label: 'Friend Gets',
            value: '₹${data.friendReward} Coupon',
            icon: Icons.person_add_alt_1,
            color: Colors.deepOrange,
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 18, color: AppSurface.textMuted),
              const SizedBox(width: 8),
              Text(
                'Minimum order: ₹${data.minOrderValue}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppSurface.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(fontSize: 12)),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.data});

  final ReferEarnDashboard data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your referral stats',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        AppSpacing.h10,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            _StatTile('Invited Friends', '${data.invitesSent}'),
            _StatTile('Joined', '${data.joinedCount}'),
            _StatTile('Ordered', '${data.orderedCount}'),
            _StatTile(
              'Earned',
              '₹${data.totalRewardsEarned.toStringAsFixed(0)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppSurface.border),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppSurface.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<ReferralHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral history',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        AppSpacing.h10,
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppSurface.border),
            ),
            child: Text(
              'No referrals yet. Share your code to get started!',
              style: GoogleFonts.poppins(color: AppSurface.textMuted),
            ),
          )
        else
          ...history.map((h) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppSurface.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                    child: Text(
                      h.friendName.isNotEmpty
                          ? h.friendName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.friendName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          h.joinedDate != null
                              ? 'Joined ${fmt.format(h.joinedDate!)}'
                              : 'Joined recently',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppSurface.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusChip(label: h.statusLabel),
                      const SizedBox(height: 4),
                      Text(
                        h.rewardStatus == 'granted'
                            ? 'Reward granted'
                            : h.rewardStatus == 'pending'
                                ? 'Reward pending'
                                : '',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppSurface.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  (Color bg, Color fg) get _colors {
    if (label.contains('Granted')) {
      return (Colors.green.shade50, Colors.green.shade800);
    }
    if (label.contains('Completed')) {
      return (Colors.blue.shade50, Colors.blue.shade800);
    }
    if (label.contains('Joined')) {
      return (Colors.orange.shade50, Colors.orange.shade900);
    }
    return (Colors.grey.shade100, Colors.grey.shade800);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _TermsNote extends StatelessWidget {
  const _TermsNote({required this.data});

  final ReferEarnDashboard data;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Self-referrals, duplicate accounts, same phone/email, and fraudulent '
      'activity are not allowed. Rewards apply after the first successful '
      'delivered order above ₹${data.minOrderValue}.',
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: AppSurface.textMuted,
        height: 1.4,
      ),
    );
  }
}

class _ReferLoadingState extends StatelessWidget {
  const _ReferLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading referral rewards…',
            style: GoogleFonts.poppins(color: AppSurface.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ReferComingSoonState extends StatelessWidget {
  const _ReferComingSoonState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReferFallbackScaffold(
      icon: Icons.card_giftcard_outlined,
      title: 'Referral Program Coming Soon',
      message:
          'We are setting up our referral rewards system. Please check back later.',
      primaryLabel: 'Retry',
      onPrimary: onRetry,
      onSecondary: () => Navigator.pop(context),
    );
  }
}

class _ReferUnavailableState extends StatelessWidget {
  const _ReferUnavailableState({required this.onGoBack});

  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    return _ReferFallbackScaffold(
      icon: Icons.info_outline_rounded,
      title: 'Referral system unavailable',
      message: 'Referral system is currently unavailable.',
      primaryLabel: 'Go Back',
      onPrimary: onGoBack,
    );
  }
}

class _ReferNetworkErrorState extends StatelessWidget {
  const _ReferNetworkErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _ReferFallbackScaffold(
      icon: Icons.wifi_off_rounded,
      title: 'No connection',
      message:
          'Please check your internet connection and try again.',
      primaryLabel: 'Retry',
      onPrimary: onRetry,
      onSecondary: () => Navigator.pop(context),
    );
  }
}

class _ReferFallbackScaffold extends StatelessWidget {
  const _ReferFallbackScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColor.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppSurface.textMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            if (onSecondary != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
