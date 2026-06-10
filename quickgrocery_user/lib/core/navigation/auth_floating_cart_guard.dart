import 'package:flutter/material.dart';

import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';

/// Hides the global floating cart while auth screens (login / OTP) are visible.
class AuthFloatingCartGuard extends StatefulWidget {
  const AuthFloatingCartGuard({super.key, required this.child});

  final Widget child;

  @override
  State<AuthFloatingCartGuard> createState() => _AuthFloatingCartGuardState();
}

class _AuthFloatingCartGuardState extends State<AuthFloatingCartGuard> {
  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.acquire();
  }

  @override
  void dispose() {
    FloatingCartSuppression.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
