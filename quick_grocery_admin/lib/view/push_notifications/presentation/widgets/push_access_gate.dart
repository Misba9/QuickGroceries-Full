import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/admin_roles.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_panel_auth.dart';
import 'package:quick_grocery_admin/view/push_notifications/services/notification_admin_service.dart';

/// Wraps push notification routes: claims, Firestore `admins`, or config fallback.
///
/// Auth is resolved once in [initState] (not on every parent rebuild). Reloads only
/// when Firebase user changes or after an explicit [_reload].
class PushAccessGate extends StatefulWidget {
  const PushAccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<PushAccessGate> createState() => _PushAccessGateState();
}

class _PushAccessGateState extends State<PushAccessGate> {
  final _bootstrapCtrl = TextEditingController();
  final _promoteUidCtrl = TextEditingController();

  StreamSubscription<User?>? _authSub;
  _PushGateSnapshot? _snapshot;
  bool _loading = true;
  String? _trackedUid;

  @override
  void initState() {
    super.initState();
    _reload(forceRefresh: true);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == _trackedUid && _snapshot != null) return;
      _trackedUid = uid;
      _reload(forceRefresh: false);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _bootstrapCtrl.dispose();
    _promoteUidCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload({required bool forceRefresh}) async {
    if (!mounted) return;
    setState(() => _loading = true);

    final snapshot = await _loadSnapshot(forceRefresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      _snapshot = snapshot;
      _loading = false;
      _trackedUid = FirebaseAuth.instance.currentUser?.uid;
    });
  }

  Future<_PushGateSnapshot> _loadSnapshot({required bool forceRefresh}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return _PushGateSnapshot(
        signedIn: false,
        uid: '',
        email: null,
        claims: const {},
        allowed: false,
      );
    }

    final allowed =
        await currentUserCanManageNotifications(forceRefresh: forceRefresh);
    final t = await u.getIdTokenResult(false);
    final claims = t.claims ?? {};

    if (kDebugMode) {
      debugLogNotificationAuth(
        uid: u.uid,
        email: u.email,
        claims: claims,
        allowed: allowed,
        reason: 'gate_snapshot',
      );
    }

    return _PushGateSnapshot(
      signedIn: true,
      uid: u.uid,
      email: u.email,
      claims: claims,
      allowed: allowed,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = _snapshot;
    if (data != null && data.allowed) {
      return widget.child;
    }

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _AccessDeniedPanel(
      data: data,
      bootstrapCtrl: _bootstrapCtrl,
      promoteUidCtrl: _promoteUidCtrl,
      onReload: () => _reload(forceRefresh: true),
    );
  }
}

class _AccessDeniedPanel extends StatelessWidget {
  const _AccessDeniedPanel({
    required this.data,
    required this.bootstrapCtrl,
    required this.promoteUidCtrl,
    required this.onReload,
  });

  final _PushGateSnapshot data;
  final TextEditingController bootstrapCtrl;
  final TextEditingController promoteUidCtrl;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColor.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Push notifications (admin)',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.signedIn
                        ? 'This account could not unlock the push tools with the current token. Try syncing claims from your Firestore `admins` record, refresh the token, or use bootstrap if configured.'
                        : 'You are not signed in with Firebase Auth. Use the admin login screen first, then return to Notifications.',
                    style: const TextStyle(height: 1.45),
                  ),
                  if (data.signedIn) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Your UID',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      data.uid,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    if (data.email != null && data.email!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Email',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        data.email!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Current claims',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _claimsPreview(data.claims),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sync from Firestore `admins`',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Writes full notification claims when your email matches an `admins` document (same check as login).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Selector<NotificationAdminService, bool>(
                      selector: (_, s) => s.busy,
                      builder: (context, busy, _) {
                        return FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: busy
                              ? null
                              : () async {
                                  try {
                                    await context
                                        .read<NotificationAdminService>()
                                        .syncClaimsFromAdminsFirestore();
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Claims synced. Reloading…',
                                        ),
                                      ),
                                    );
                                    onReload();
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.cloud_sync_outlined),
                          label: const Text('Sync admin claims'),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Refresh token',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context
                            .read<NotificationAdminService>()
                            .refreshAuthToken();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ID token refreshed')),
                        );
                        onReload();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh claims'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bootstrap (optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bootstrapCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Bootstrap secret',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Selector<NotificationAdminService, bool>(
                      selector: (_, s) => s.busy,
                      builder: (context, busy, _) {
                        return FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: busy
                              ? null
                              : () async {
                                  final secret = bootstrapCtrl.text.trim();
                                  if (secret.length < 12) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Secret must match server (12+ chars)',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  try {
                                    await context
                                        .read<NotificationAdminService>()
                                        .applyAdminClaimsBootstrap(secret);
                                    if (!context.mounted) return;
                                    bootstrapCtrl.clear();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Admin claims applied. Reloading…',
                                        ),
                                      ),
                                    );
                                    onReload();
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Apply bootstrap to my account'),
                        );
                      },
                    ),
                    if (hasElevatedAdmin(data.claims)) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Promote another user',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: promoteUidCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Target Firebase Auth UID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Selector<NotificationAdminService, bool>(
                        selector: (_, s) => s.busy,
                        builder: (context, busy, _) {
                          return OutlinedButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                                    final id = promoteUidCtrl.text.trim();
                                    if (id.isEmpty) return;
                                    try {
                                      await context
                                          .read<NotificationAdminService>()
                                          .promoteUserToAdmin(id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Claims set for $id'),
                                        ),
                                      );
                                      promoteUidCtrl.clear();
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Grant admin + push access to UID'),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _claimsPreview(Map<Object?, Object?> claims) {
    if (claims.isEmpty) return '{}';
    return claims.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _PushGateSnapshot {
  _PushGateSnapshot({
    required this.signedIn,
    required this.uid,
    required this.email,
    required this.claims,
    required this.allowed,
  });

  final bool signedIn;
  final String uid;
  final String? email;
  final Map<Object?, Object?> claims;
  final bool allowed;
}
