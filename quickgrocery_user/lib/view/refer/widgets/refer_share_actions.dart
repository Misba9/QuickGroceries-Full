import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp, Telegram, SMS, Email, Copy Link, and native share.
class ReferShareActions extends StatelessWidget {
  const ReferShareActions({
    super.key,
    required this.message,
    required this.onNativeShare,
    required this.canShare,
    this.onDisabledTap,
  });

  final String message;
  final VoidCallback onNativeShare;
  final bool canShare;
  final VoidCallback? onDisabledTap;

  Future<void> _launch(Uri uri) async {
    if (!canShare) {
      onDisabledTap?.call();
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyLink(BuildContext context) {
    if (!canShare) {
      onDisabledTap?.call();
      return;
    }
    Clipboard.setData(ClipboardData(text: message));
    AppSnackBar.success('Invite message copied', context: context);
  }

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(message);

    final chips = <_ShareChipData>[
      _ShareChipData(
        'WhatsApp',
        Icons.chat_rounded,
        const Color(0xFF25D366),
        () => _launch(Uri.parse('https://wa.me/?text=$encoded')),
      ),
      _ShareChipData(
        'Telegram',
        Icons.send_rounded,
        const Color(0xFF0088CC),
        () => _launch(
          Uri.parse('https://t.me/share/url?url=&text=$encoded'),
        ),
      ),
      _ShareChipData(
        'SMS',
        Icons.sms_outlined,
        AppColor.primary,
        () => _launch(Uri.parse('sms:?body=$encoded')),
      ),
      _ShareChipData(
        'Email',
        Icons.email_outlined,
        Colors.deepOrange,
        () => _launch(
          Uri.parse(
            'mailto:?subject=${Uri.encodeComponent('Quick Groceries — Referral Invite')}&body=$encoded',
          ),
        ),
      ),
      _ShareChipData(
        'Copy Link',
        Icons.link_rounded,
        Colors.indigo,
        () => _copyLink(context),
      ),
      _ShareChipData(
        'Share',
        Icons.ios_share_rounded,
        Colors.grey,
        () {
          if (!canShare) {
            onDisabledTap?.call();
            return;
          }
          onNativeShare();
        },
      ),
    ];

    return Opacity(
      opacity: canShare ? 1 : 0.55,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: chips
            .map(
              (c) => _ShareChip(
                label: c.label,
                icon: c.icon,
                color: c.color,
                onTap: c.onTap,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShareChipData {
  const _ShareChipData(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ShareChip extends StatelessWidget {
  const _ShareChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final w = (MediaQuery.sizeOf(context).width - 52) / 3;
    return Material(
      color: surface.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: w.clamp(100, 140),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: surface.border),
            boxShadow: AppShadow.cardOf(context),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: surface.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
