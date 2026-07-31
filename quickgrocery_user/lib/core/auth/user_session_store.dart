import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/user/search_history_store.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';

/// Clears user-scoped local data on logout / account switch.
///
/// Preserves language, permissions, device id, promo timing prefs, and the
/// **public** home catalog cache so logout can hand off to guest Home without
/// replaying the cold-start splash.
abstract final class UserSessionStore {
  static Future<void> clearUserData(SharedPreferences prefs) async {
    await UserProfileCache.clearOnLogout();
    await SearchHistoryStore.clear();
  }
}
