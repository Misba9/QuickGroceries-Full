import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/view/app_content/data/app_content_repository.dart';
import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';

final appContentRepositoryProvider = Provider<AppContentRepository>((ref) {
  return AppContentRepository(firestore: ref.watch(firestoreProvider));
});

/// Live homepage copy from Firestore — falls back to [AppContentConfig.defaults].
final appContentStreamProvider =
    StreamProvider.autoDispose<AppContentConfig>((ref) {
  return ref.watch(appContentRepositoryProvider).watch();
});
