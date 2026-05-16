import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/support/data/support_settings_repository.dart';
import 'package:quickgrocery/view/support/models/support_settings_config.dart';

final supportSettingsRepositoryProvider =
    Provider<SupportSettingsRepository>((ref) {
  return SupportSettingsRepository(firestore: ref.watch(firestoreProvider));
});

/// Live support contact from Firestore — falls back to [SupportSettingsConfig.defaults].
final supportSettingsStreamProvider =
    StreamProvider.autoDispose<SupportSettingsConfig>((ref) {
  return ref.watch(supportSettingsRepositoryProvider).watch();
});
