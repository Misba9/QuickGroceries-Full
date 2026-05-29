import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/core/widgets/firestore_connection_lost.dart';
import 'package:quickgrocery/maintenance/presentation/providers/maintenance_providers.dart';
import 'package:quickgrocery/maintenance/presentation/screens/maintenance_screen.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';

/// Wraps authenticated app content — shows maintenance screen when blocked.
class MaintenanceGate extends ConsumerStatefulWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends ConsumerState<MaintenanceGate> {
  int _legacyKey = 0;

  Stream<DocumentSnapshot> _legacyStoreStream() {
    return FirebaseFirestore.instance
        .collection('admins')
        .doc('4elRGQlC662hdcE1a1Ls')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(maintenanceStatusProvider);

    return statusAsync.when(
      loading: () => HomeShimmer.landingTabShell(),
      error: (e, _) => FirestoreConnectionLost(
        error: e,
        onRetry: () {
          ref.invalidate(maintenanceStatusProvider);
          ref.invalidate(maintenanceConfigStreamProvider);
        },
      ),
      data: (status) {
        // Legacy admins doc still respected when maintenance doc not enabled.
        if (!status.config.enabled &&
            status.config.legacyStoreActive &&
            !status.config.usesSystemControls) {
          return StreamBuilder<DocumentSnapshot>(
            key: ValueKey<int>(_legacyKey),
            stream: _legacyStoreStream(),
            builder: (context, legacySnap) {
              if (!legacySnap.hasData) {
                return HomeShimmer.landingTabShell();
              }
              if (!legacySnap.data!.exists) {
                return MaintenanceScreen(
                  status: status,
                  onRetry: () => setState(() => _legacyKey++),
                );
              }
              final data =
                  legacySnap.data!.data() as Map<String, dynamic>? ?? {};
              final isActive = data['isActive'] as bool? ?? false;
              if (!isActive) {
                return MaintenanceScreen(
                  status: status,
                  onRetry: () => setState(() => _legacyKey++),
                );
              }
              return widget.child;
            },
          );
        }

        if (status.showFullScreenBlock) {
          return MaintenanceScreen(
            status: status,
            onRetry: () {
              ref.invalidate(maintenanceStatusProvider);
            },
          );
        }

        return widget.child;
      },
    );
  }
}

/// Snackbar when maintenance blocks checkout.
void showMaintenanceOrderBlocked(BuildContext context, {String? message}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message ?? 'Ordering disabled by admin'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
