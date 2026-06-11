import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/view/support/data/support_settings_repository.dart';
import 'package:quickgrocery/view/support/models/support_settings.dart';

final supportSettingsRepositoryProvider = Provider<SupportSettingsRepository>(
  (ref) => SupportSettingsRepository(),
);

/// Live support contact from admin **Support Settings**.
final supportSettingsStreamProvider = StreamProvider<SupportSettings>((ref) {
  return ref.watch(supportSettingsRepositoryProvider).watch();
});
