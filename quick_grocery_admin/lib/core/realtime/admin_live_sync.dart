import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Snapshot of a realtime Firestore listener for admin chrome.
class AdminLiveSyncState {
  const AdminLiveSyncState({
    this.isLoading = true,
    this.hasError = false,
    this.errorMessage,
    this.lastSyncAt,
    this.isFromCache = false,
    this.pendingWrites = false,
  });

  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final DateTime? lastSyncAt;
  final bool isFromCache;
  final bool pendingWrites;

  bool get isLive =>
      !isLoading && !hasError && lastSyncAt != null && !isFromCache;

  AdminLiveSyncState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    DateTime? lastSyncAt,
    bool? isFromCache,
    bool? pendingWrites,
    bool clearError = false,
  }) {
    return AdminLiveSyncState(
      isLoading: isLoading ?? this.isLoading,
      hasError: clearError ? false : (hasError ?? this.hasError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isFromCache: isFromCache ?? this.isFromCache,
      pendingWrites: pendingWrites ?? this.pendingWrites,
    );
  }

  static AdminLiveSyncState fromSnapshotMetadata(
    SnapshotMetadata metadata, {
    required AdminLiveSyncState previous,
    Object? error,
  }) {
    if (error != null) {
      return previous.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: error.toString(),
      );
    }
    return previous.copyWith(
      isLoading: false,
      clearError: true,
      lastSyncAt: DateTime.now(),
      isFromCache: metadata.isFromCache,
      pendingWrites: metadata.hasPendingWrites,
    );
  }
}

/// Compact live-sync status chip used on list/management screens.
///
/// Uses a finite [SizedBox] width so an inner [Expanded] never sees unbounded
/// horizontal constraints (which crashes Flutter Web layout).
class AdminLiveSyncBar extends StatelessWidget {
  const AdminLiveSyncBar({
    super.key,
    required this.state,
    this.label = 'Catalog',
    this.maxWidth = 320,
  });

  final AdminLiveSyncState state;
  final String label;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final time = state.lastSyncAt;
    final timeLabel = time != null
        ? DateFormat('HH:mm:ss').format(time.toLocal())
        : '—';

    final statusColor = state.hasError
        ? Colors.red
        : state.isLive
            ? Colors.green
            : Colors.orange;

    final statusText = state.hasError
        ? 'Error'
        : state.isLoading
            ? 'Connecting…'
            : state.isLive
                ? 'Live'
                : state.isFromCache
                    ? 'Cached'
                    : 'Syncing';

    return SizedBox(
      width: maxWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                state.hasError
                    ? Icons.cloud_off_rounded
                    : state.isLive
                        ? Icons.sensors_rounded
                        : Icons.cloud_queue_rounded,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (state.pendingWrites) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Saving…',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.hasError
                          ? (state.errorMessage ?? 'Listener failed')
                          : 'Last sync $timeLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
