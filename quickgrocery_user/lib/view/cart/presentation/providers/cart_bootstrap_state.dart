import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True after [CartBootstrap] has wired legacy services to [CartNotifier].
final cartBootstrapReadyProvider = StateProvider<bool>((ref) => false);
