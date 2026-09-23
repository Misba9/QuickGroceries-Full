import 'package:flutter/material.dart';

import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// Two-step confirmation for [Delete Account]. No network calls.
class AccountDeletionConfirmFlow {
  static Future<bool> confirm(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(context.l10n.deleteAccountTitle),
        content: Text(context.l10n.deleteAccountBody),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            key: const Key('deleteAccountConfirmCancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const Key('deleteAccountConfirmDelete'),
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            child: Text(context.l10n.delete_account),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return false;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(context.l10n.deleteAccountSecondTitle),
        content: Text(context.l10n.deleteAccountSecondBody),
        actionsOverflowButtonSpacing: 8,
        actions: [
          TextButton(
            key: const Key('deleteAccountSecondCancel'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            key: const Key('deleteAccountSecondConfirm'),
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
            child: Text(context.l10n.yesDeleteMyAccount),
          ),
        ],
      ),
    );
    return second == true;
  }
}
