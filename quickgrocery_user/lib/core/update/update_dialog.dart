import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/update/app_update_config.dart';

/// Result of the optional / force update dialog.
enum UpdateDialogAction {
  updateNow,
  later,
}

Future<UpdateDialogAction?> showAppUpdateDialog(
  BuildContext context, {
  required AppUpdateConfig config,
  required bool forceUpdate,
  String? installedVersion,
  String? latestVersion,
}) {
  final useCupertino = Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS;

  if (useCupertino) {
    return showCupertinoDialog<UpdateDialogAction>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: CupertinoAlertDialog(
          title: Text(
            forceUpdate
                ? (config.updateTitle.isNotEmpty
                    ? config.updateTitle
                    : 'Update Available')
                : 'Update Available',
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              forceUpdate
                  ? (config.updateMessage.isNotEmpty
                      ? '${config.updateMessage}\n\nThis update is required to continue using the app.'
                      : 'A newer version of the app is available.\nPlease update to enjoy the latest features and improvements.\n\nThis update is required to continue using the app.')
                  : 'A newer version of the app is available.\nPlease update to enjoy the latest features and improvements.',
            ),
          ),
          actions: [
            if (!forceUpdate)
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx, UpdateDialogAction.later),
                child: const Text('Later'),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () =>
                  Navigator.pop(ctx, UpdateDialogAction.updateNow),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  return showGeneralDialog<UpdateDialogAction>(
    context: context,
    barrierDismissible: !forceUpdate,
    barrierLabel: 'App update',
    barrierColor: Colors.black54,
    transitionDuration: AppMotion.medium,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: Center(
            child: _MaterialUpdateCard(
              config: config,
              forceUpdate: forceUpdate,
              installedVersion: installedVersion,
              latestVersion: latestVersion,
              onUpdateNow: () =>
                  Navigator.pop(ctx, UpdateDialogAction.updateNow),
              onLater: forceUpdate
                  ? null
                  : () => Navigator.pop(ctx, UpdateDialogAction.later),
            ),
          ),
        ),
      );
    },
  );
}

/// Prompt after a flexible update finishes downloading.
Future<bool> showRestartToInstallDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Update ready',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'The update has been downloaded. Restart to install.',
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Restart'),
        ),
      ],
    ),
  );
  return result == true;
}

class _MaterialUpdateCard extends StatelessWidget {
  const _MaterialUpdateCard({
    required this.config,
    required this.forceUpdate,
    required this.onUpdateNow,
    this.onLater,
    this.installedVersion,
    this.latestVersion,
  });

  final AppUpdateConfig config;
  final bool forceUpdate;
  final VoidCallback onUpdateNow;
  final VoidCallback? onLater;
  final String? installedVersion;
  final String? latestVersion;

  @override
  Widget build(BuildContext context) {
    final title = config.updateTitle.isNotEmpty
        ? config.updateTitle
        : '✨ New version available';
    final message = config.updateMessage.isNotEmpty
        ? config.updateMessage
        : "We've added new features and improved performance.";

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadow.raised,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                forceUpdate ? title : '✨ New version available',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              if (latestVersion != null && latestVersion!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'v$latestVersion'
                  '${installedVersion != null ? '  ·  you have v$installedVersion' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppSurface.of(context).textMuted,
                  ),
                ),
              ],
              SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.4,
                  color: AppSurface.of(context).textMuted,
                ),
              ),
              if (!forceUpdate) ...[
                SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '• Bug fixes\n• Performance improvements\n• New features',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.5,
                      color: AppSurface.of(context).textSecondary,
                    ),
                  ),
                ),
              ],
              if (forceUpdate) ...[
                SizedBox(height: 12),
                Text(
                  'This update is required to continue using the app.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppSurface.of(context).danger,
                  ),
                ),
              ],
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onUpdateNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: Text(
                    'Update Now',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (onLater != null)
                TextButton(
                  onPressed: onLater,
                  child: Text(
                    'Later',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppSurface.of(context).textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
