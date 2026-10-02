import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/widgets/brand_logo_splash.dart';

/// Brand yellow — native splash + Flutter startup must match exactly.
const kLaunchYellow = Color(0xFFFFDE59);

/// Startup UI:
///
/// 1. Yellow + logo (native → Flutter bridge, total ~0–400ms) — no text/spinner
/// 2. Full-screen category animation until Home is ready
/// 3. Soft 250ms fade → Home
class AppAnimatedSplash extends ConsumerStatefulWidget {
  const AppAnimatedSplash({
    super.key,
    this.appReady = false,
    this.onReadyToOpenHome,
    this.onExitComplete,
  });

  final bool appReady;

  /// Optional — Home is mounted by the shell when bootstrap is ready.
  final VoidCallback? onReadyToOpenHome;

  /// Fired after splash fade-out — shell may remove this splash.
  final VoidCallback? onExitComplete;

  @override
  ConsumerState<AppAnimatedSplash> createState() => _AppAnimatedSplashState();
}

class _AppAnimatedSplashState extends ConsumerState<AppAnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _exitFade;
  late final Animation<double> _splashOpacity;

  late final AnimationController _phaseFade;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _categoryOpacity;

  bool _showLogo = true;
  bool _categoriesVisible = false;
  bool _requestCategoryExit = false;
  bool _exitStarted = false;
  bool _notifiedHomeUnderlay = false;
  bool _notifiedExitComplete = false;
  bool _assetsWarmed = false;
  bool _seeded = false;
  bool _readyHandled = false;
  bool _logoHoldScheduled = false;
  AnimationController? _logoHoldCtrl;

  @override
  void initState() {
    super.initState();

    _exitFade = AnimationController(
      vsync: this,
      duration: LoadingConstants.exitFade,
    );
    _splashOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _exitFade,
        curve: LoadingConstants.exitCurve,
      ),
    );

    _phaseFade = AnimationController(
      vsync: this,
      duration: LoadingConstants.logoToCategoryFade,
    );
    _logoOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _phaseFade, curve: Curves.easeInCubic),
    );
    _categoryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _phaseFade, curve: LoadingConstants.revealCurve),
    );

    LaunchLogoHold.markStarted();

    // Warm path (Home already ready): finish current logo hold if any, then
    // one category beat and exit.
    if (widget.appReady) {
      _readyHandled = true;
      _requestCategoryExit = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_precacheStartupAssets());
      _scheduleLogoHoldThenCategories();
    });
  }

  void _scheduleLogoHoldThenCategories() {
    if (_logoHoldScheduled) return;
    _logoHoldScheduled = true;

    final remaining = LaunchLogoHold.remaining;
    if (remaining == Duration.zero) {
      _startCategories();
      return;
    }

    // Frame-synced hold — no Timer. Tick until Step 1 (0–400ms) completes.
    _logoHoldCtrl?.dispose();
    final hold = AnimationController(vsync: this, duration: remaining);
    _logoHoldCtrl = hold;
    hold.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _startCategories();
    });
    hold.forward();
  }

  Future<void> _precacheStartupAssets() async {
    if (_assetsWarmed || !mounted) return;
    _assetsWarmed = true;
    try {
      unawaited(
        precacheImage(
          const AssetImage(LoadingConstants.logoAsset),
          context,
        ),
      );
      unawaited(LoadingManager.boot(context: context));
    } catch (_) {}
  }

  void _startCategories() {
    if (!mounted || _categoriesVisible) {
      if (_categoriesVisible && widget.appReady) _onAppBecameReady();
      return;
    }

    setState(() {
      _categoriesVisible = true;
      if (widget.appReady) {
        _requestCategoryExit = true;
        _readyHandled = true;
      }
    });
    _phaseFade.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _showLogo = false);
    });
  }

  @override
  void didUpdateWidget(covariant AppAnimatedSplash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appReady && !oldWidget.appReady) {
      _onAppBecameReady();
    }
  }

  void _onAppBecameReady() {
    if (_exitStarted || _readyHandled) return;
    if (!_categoriesVisible) {
      // Still on logo — categories will pick up exit when started.
      _readyHandled = true;
      _requestCategoryExit = true;
      return;
    }
    _readyHandled = true;
    if (!_requestCategoryExit) {
      setState(() => _requestCategoryExit = true);
    }
  }

  void _onCategoryExitReady() {
    if (_exitStarted || !mounted) return;
    _exitStarted = true;

    if (!_notifiedHomeUnderlay) {
      _notifiedHomeUnderlay = true;
      widget.onReadyToOpenHome?.call();
    }

    _afterFrames(1, () {
      if (!mounted || _notifiedExitComplete) return;
      _exitFade.forward(from: 0).whenComplete(() {
        if (!mounted || _notifiedExitComplete) return;
        _notifiedExitComplete = true;
        widget.onExitComplete?.call();
      });
    });
  }

  void _afterFrames(int count, VoidCallback then) {
    var left = count;
    void step(Duration _) {
      left--;
      if (left <= 0) {
        then();
        return;
      }
      SchedulerBinding.instance.addPostFrameCallback(step);
    }

    SchedulerBinding.instance.addPostFrameCallback(step);
    SchedulerBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    _logoHoldCtrl?.dispose();
    _exitFade.dispose();
    _phaseFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      appBootstrapProvider.select((s) => s.homeSnapshot.categories),
      (prev, next) {
        if (_seeded || next.isEmpty) return;
        LoadingManager.seed(next);
        _seeded = true;
      },
    );

    if (widget.appReady &&
        _categoriesVisible &&
        !_requestCategoryExit &&
        !_exitStarted &&
        !_readyHandled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAppBecameReady();
      });
    }

    const bg = kLaunchYellow;

    return FadeTransition(
      opacity: _splashOpacity,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: bg,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: ColoredBox(
          color: bg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_categoriesVisible)
                FadeTransition(
                  opacity: _categoryOpacity,
                  child: CategoryLoadingWidget(
                    compact: false,
                    fullScreen: true,
                    playing: true,
                    requestExit: _requestCategoryExit,
                    style: const CategoryLoadingStyle(
                      cycleDuration: LoadingConstants.categoryCycle,
                      background: bg,
                      textColor: Color(0xFF1A1A1A),
                    ),
                    onExitReady: _onCategoryExitReady,
                  ),
                ),
              // STEP 1 — yellow + logo (0–400ms). Completely gone after phase.
              if (_showLogo)
                IgnorePointer(
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: const BrandLogoSplash(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
