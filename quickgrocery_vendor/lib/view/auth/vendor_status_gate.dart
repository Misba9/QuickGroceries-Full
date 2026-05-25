import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/vendor_model.dart';
import '../../services/vendor_auth_service.dart';
import 'login_screen.dart';

/// Logs the vendor out when admin suspends or blocks the account in real time.
class VendorStatusGate extends StatefulWidget {
  const VendorStatusGate({super.key, required this.vendorId, required this.child});

  final String vendorId;
  final Widget child;

  @override
  State<VendorStatusGate> createState() => _VendorStatusGateState();
}

class _VendorStatusGateState extends State<VendorStatusGate> {
  final _auth = VendorAuthService();
  bool _handledBlock = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(widget.vendorId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() ?? {};
          final blocked = VendorModel.loginBlockedReason(data);
          if (blocked != null && !_handledBlock) {
            _handledBlock = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _forceLogout(blocked);
            });
          }
        }
        return widget.child;
      },
    );
  }

  Future<void> _forceLogout(String message) async {
    await _auth.logout();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Account suspended'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
