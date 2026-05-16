import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/view/app_content/models/app_content_config.dart';
import 'package:quickgrocery/view/app_content/presentation/providers/app_content_providers.dart';

extension AppContentRefX on WidgetRef {
  AppContentConfig get appContent =>
      watch(appContentStreamProvider).value ?? AppContentConfig.defaults;

  bool get appContentLoading {
    final async = watch(appContentStreamProvider);
    return async.isLoading && !async.hasValue;
  }
}
