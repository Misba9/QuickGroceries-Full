import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/auth/auth_user_provider.dart';
import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_login_launcher.dart';
import 'package:quickgrocery/core/auth/widgets/login_required_dialog.dart';

/// Central auth gate for guest-restricted actions (checkout, wishlist, etc.).
abstract final class GuestAuthGuard {
  static Future<bool> requireAuth(
    BuildContext context,
    WidgetRef ref, {
    GuestPostLoginAction postLogin = GuestPostLoginAction.none,
  }) async {
    final authUser = resolveAuthUser(ref.read(authUserProvider));
    if (authUser != null || FirebaseAuth.instance.currentUser != null) {
      return true;
    }

    final proceed = await LoginRequiredDialog.show(context);
    if (!proceed || !context.mounted) return false;

    if (postLogin != GuestPostLoginAction.none) {
      GuestAuthCoordinator.setPendingAction(postLogin);
    }

    await GuestLoginLauncher.launch(context, ref);

    if (!context.mounted) return false;
    return FirebaseAuth.instance.currentUser != null;
  }
}
