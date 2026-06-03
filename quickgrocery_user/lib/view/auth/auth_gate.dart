import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/core/user/user_profile_cache.dart';
import 'package:quickgrocery/view/auth/screens/customer_profile_add_screen.dart';
import 'package:quickgrocery/view/auth/screens/login_screen.dart';
import 'package:quickgrocery/view/home/screens/landing_screen.dart';

import 'package:quickgrocery/core/user/user_profile_repository.dart';

/// Routes authenticated users: home vs one-time profile onboarding.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = UserProfileRepository();
  String? _resolvedUid;
  bool? _needsOnboarding;
  bool _loading = false;
  bool _resolveInFlight = false;

  static const _networkTimeout = Duration(seconds: 10);

  /// Used by [_BootSplash] if profile resolution never finishes.
  void forceExitLoading({required bool needsOnboarding}) {
    if (!mounted) return;
    if (!_loading && _needsOnboarding != null) return;
    setState(() {
      _loading = false;
      _needsOnboarding = needsOnboarding;
    });
  }

  Future<bool> _profileCompleteFromCache(String uid) async {
    if (await UserProfileCache.isProfileCompleteCached()) return true;
    final cached = await UserProfileCache.readProfile();
    final name = (cached['name'] ?? '').trim();
    final gender = (cached['gender'] ?? '').trim();
    return name.isNotEmpty && gender.isNotEmpty;
  }

  Future<void> _refreshProfileInBackground(User user) async {
    try {
      await _repo
          .hydrateLocal(user.uid)
          .timeout(_networkTimeout);
      final complete = await _repo
          .isProfileComplete(user.uid)
          .timeout(_networkTimeout);
      if (!mounted || _resolvedUid != user.uid) return;
      final needsOnboarding = !complete;
      if (_needsOnboarding != needsOnboarding) {
        setState(() => _needsOnboarding = needsOnboarding);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthGate] background profile refresh failed: $e');
      }
    }
  }

  void _applyResolution(String uid, bool needsOnboarding) {
    if (!mounted || _resolvedUid != uid) return;
    setState(() {
      _needsOnboarding = needsOnboarding;
      _loading = false;
    });
  }

  Future<void> _resolveForUser(User user) async {
    if (_resolveInFlight && _resolvedUid == user.uid) return;
    _resolveInFlight = true;

    setState(() {
      _loading = true;
      _resolvedUid = user.uid;
      _needsOnboarding = null;
    });

    var needsOnboarding = true;

    try {
      final cachedComplete = await _profileCompleteFromCache(user.uid);
      if (cachedComplete) {
        needsOnboarding = false;
        _applyResolution(user.uid, needsOnboarding);
        unawaited(_refreshProfileInBackground(user));
        return;
      }

      await _repo.hydrateLocal(user.uid).timeout(_networkTimeout);
      final complete =
          await _repo.isProfileComplete(user.uid).timeout(_networkTimeout);
      needsOnboarding = !complete;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AuthGate] profile resolve failed: $e');
        debugPrintStack(stackTrace: st);
      }
      needsOnboarding = !(await _profileCompleteFromCache(user.uid));
    } finally {
      _resolveInFlight = false;
      if (mounted && _resolvedUid == user.uid && (_loading || _needsOnboarding == null)) {
        _applyResolution(user.uid, needsOnboarding);
      }
    }
  }

  /// Call after profile registration completes.
  static void markOnboardingComplete(BuildContext context) {
    final state = context.findAncestorStateOfType<_AuthGateState>();
    state?.setState(() => state._needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data ?? FirebaseAuth.instance.currentUser;

        if (snap.connectionState == ConnectionState.waiting && user == null) {
          return const _BootSplash();
        }

        if (user == null) {
          _resolvedUid = null;
          _needsOnboarding = null;
          _loading = false;
          _resolveInFlight = false;
          return const LoginScreen();
        }

        if (_resolvedUid != user.uid) {
          _resolveForUser(user);
        }

        if (_needsOnboarding == null || _loading) {
          return _BootSplash(gateState: this);
        }

        if (_needsOnboarding!) {
          return const CustomerDetailsAddScreen();
        }

        return const LandingScreen();
      },
    );
  }
}

class _BootSplash extends StatefulWidget {
  const _BootSplash({this.gateState});

  final _AuthGateState? gateState;

  @override
  State<_BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<_BootSplash> {
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.acquire();
    _watchdog = Timer(const Duration(seconds: 12), _onWatchdog);
  }

  Future<void> _onWatchdog() async {
    if (!mounted) return;
    final gate = widget.gateState;
    if (gate == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final fromCache = await gate._profileCompleteFromCache(uid);
    gate.forceExitLoading(needsOnboarding: !fromCache);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    FloatingCartSuppression.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
