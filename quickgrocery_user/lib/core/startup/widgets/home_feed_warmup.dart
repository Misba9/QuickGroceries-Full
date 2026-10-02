import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No-op during splash. Home sections subscribe themselves after arm frames.
///
/// Previously this watched banners/categories/rails during Category Animation,
/// which parsed Firestore snapshots on the UI isolate and caused skipped frames.
class HomeFeedWarmup extends ConsumerWidget {
  const HomeFeedWarmup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox.shrink();
  }
}
