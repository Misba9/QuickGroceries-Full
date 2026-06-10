import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/support/data/support_settings_repository.dart';
import 'package:quickgrocery/view/support/models/support_settings.dart';

final supportSettingsRepositoryProvider =
    Provider<SupportSettingsRepository>((ref) {
  return SupportSettingsRepository(firestore: ref.watch(firestoreProvider));
});

/// Realtime support contact from admin **Settings → Support Settings**.
final supportSettingsStreamProvider =
    StreamProvider.autoDispose<SupportSettings>((ref) {
  return ref.watch(supportSettingsRepositoryProvider).watch();
});
