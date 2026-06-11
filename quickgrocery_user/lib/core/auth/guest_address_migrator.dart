import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/view/address/data/guest_address_store.dart';

/// Guest delivery snapshots are not migrated after login — users add addresses
/// manually from checkout or the address book.
abstract final class GuestAddressMigrator {
  static Future<void> discardPendingAfterLogin(WidgetRef ref) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await GuestAddressStore.clear(prefs);
  }
}
