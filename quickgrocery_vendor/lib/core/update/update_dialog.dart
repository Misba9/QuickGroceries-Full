import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery_vendor/core/update/app_update_config.dart';

enum UpdateDialogAction { updateNow, later }

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
          title: Text(forceUpdate ? config.updateTitle : 'Update Available'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              forceUpdate
                  ? '${config.updateMessage}\n\nThis update is required to continue using the app.'
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

  return showDialog<UpdateDialogAction>(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (ctx) => PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        title: Text(
          forceUpdate ? config.updateTitle : '✨ New version available',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.updateMessage, style: GoogleFonts.poppins(fontSize: 14)),
            if (!forceUpdate) ...[
              const SizedBox(height: 12),
              Text(
                '• Bug fixes\n• Performance improvements\n• New features',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
            if (forceUpdate) ...[
              const SizedBox(height: 12),
              Text(
                'This update is required to continue using the app.',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(ctx, UpdateDialogAction.later),
              child: const Text('Later'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, UpdateDialogAction.updateNow),
            child: const Text('Update Now'),
          ),
        ],
      ),
    ),
  );
}

Future<bool> showRestartToInstallDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Update ready',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
      ),
      content: const Text('The update has been downloaded. Restart to install.'),
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
