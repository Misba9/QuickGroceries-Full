import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/core/startup/home_data_cache.dart';
import 'package:quickgrocery/core/user/search_history_store.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';

/// Clears user-scoped local data on logout / account switch.
///
/// Preserves language, permissions, device id, and promo timing prefs.
abstract final class UserSessionStore {
  static Future<void> clearUserData(SharedPreferences prefs) async {
    await UserProfileCache.clearOnLogout();
    await HomeDataCache.clearOnLogout(prefs);
    await SearchHistoryStore.clear();
  }
}
