import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/sms/services/admin_roles.dart';
import 'package:quick_grocery_admin/view/sms/services/admin_sms_auth.dart';
import 'package:quick_grocery_admin/view/sms/services/sms_admin_service.dart';

/// Wraps SMS routes: resolves access via claims, Firestore `admins`, or config fallback.
class SmsAccessGate extends StatefulWidget {
  const SmsAccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<SmsAccessGate> createState() => _SmsAccessGateState();
}

class _SmsAccessGateState extends State<SmsAccessGate> {
  final _bootstrapCtrl = TextEditingController();
  final _promoteUidCtrl = TextEditingController();
  int _reloadToken = 0;

  @override
  void dispose() {
    _bootstrapCtrl.dispose();
    _promoteUidCtrl.dispose();
    super.dispose();
  }

  Future<_SmsGateSnapshot> _load() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return _SmsGateSnapshot(
        signedIn: false,
        uid: '',
        email: null,
        claims: const {},
        allowed: false,
      );
    }
    final allowed = await currentUserCanManageSms(forceRefresh: true);
    final t = await u.getIdTokenResult(false);
    final claims = t.claims ?? {};
    debugLogNotificationAuth(
      uid: u.uid,
      email: u.email,
      claims: claims,
      allowed: allowed,
      reason: 'gate_snapshot',
    );
    return _SmsGateSnapshot(
      signedIn: true,
      uid: u.uid,
      email: u.email,
      claims: claims,
      allowed: allowed,
    );
  }

  void _bump() => setState(() => _reloadToken++);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SmsGateSnapshot>(
      key: ValueKey(_reloadToken),
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!;
        if (data.allowed) {
          return widget.child;
        }
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
                          Icon(Icons.lock_outline_rounded,
                              color: AppColor.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'SMS admin only',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data.signedIn
                            ? 'This account could not unlock the SMS tools with the current token. Try syncing claims from your Firestore `admins` record, refresh the token, or use bootstrap if configured.'
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
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: context.watch<SmsAdminService>().busy
                              ? null
                              : () async {
                                  try {
                                    await context
                                        .read<SmsAdminService>()
                                        .syncClaimsFromAdminsFirestore();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Claims synced. Reloading…',
                                          ),
                                        ),
                                      );
                                      _bump();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.cloud_sync_outlined),
                          label: const Text('Sync admin claims'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Refresh token',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'After claims change in Firebase Console or via sync, refresh the ID token.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await context
                                .read<SmsAdminService>()
                                .refreshAuthToken();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ID token refreshed'),
                                ),
                              );
                              _bump();
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh claims'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bootstrap (optional)',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'If ADMIN_BOOTSTRAP_SECRET is set on Cloud Functions (12+ chars), paste it once here.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bootstrapCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Bootstrap secret',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: context.watch<SmsAdminService>().busy
                              ? null
                              : () async {
                                  final secret = _bootstrapCtrl.text.trim();
                                  if (secret.length < 12) {
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
                                        .read<SmsAdminService>()
                                        .applyAdminClaimsBootstrap(secret);
                                    if (context.mounted) {
                                      _bootstrapCtrl.clear();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Admin claims applied. Reloading…',
                                          ),
                                        ),
                                      );
                                      _bump();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.verified_user_outlined),
                          label: const Text('Apply bootstrap to my account'),
                        ),
                        if (hasElevatedAdmin(data.claims)) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Promote another user',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your token already has elevated admin claims.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _promoteUidCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Target Firebase Auth UID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: context.watch<SmsAdminService>().busy
                                ? null
                                : () async {
                                    final id = _promoteUidCtrl.text.trim();
                                    if (id.isEmpty) return;
                                    try {
                                      await context
                                          .read<SmsAdminService>()
                                          .promoteUserToAdmin(id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Claims set for $id',
                                            ),
                                          ),
                                        );
                                        _promoteUidCtrl.clear();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Grant admin + SMS to UID'),
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
      },
    );
  }

  String _claimsPreview(Map<Object?, Object?> claims) {
    if (claims.isEmpty) return '{}';
    final entries = claims.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    return entries;
  }
}

class _SmsGateSnapshot {
  _SmsGateSnapshot({
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
