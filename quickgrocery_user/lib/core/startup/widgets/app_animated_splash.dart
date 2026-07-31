import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';
import 'package:quickgrocery/core/startup/widgets/home_feed_warmup.dart';
import 'package:quickgrocery/models/category_model.dart';

/// Native launch / logo yellow — OS splash → logo → categories → Home.
const kLaunchYellow = Color(0xFFFFDE59);

/// Continuous startup motion: logo → categories → Home (no blank frames).
///
/// Exit does **not** fade the full page. When bootstrap is ready, the current
/// category cycle finishes; Home is mounted underneath; splash is removed.
class AppAnimatedSplash extends ConsumerStatefulWidget {
  const AppAnimatedSplash({
    super.key,
    this.appReady = false,
    this.onReadyToOpenHome,
    this.onExitComplete,
  });

  final bool appReady;

  /// Fired when Home should mount under this splash (category exit done).
  final VoidCallback? onReadyToOpenHome;

  /// Fired after Home has painted — shell may remove this splash.
  final VoidCallback? onExitComplete;

  @override
  ConsumerState<AppAnimatedSplash> createState() => _AppAnimatedSplashState();
}

enum _SplashPhase { logo, categories }

class _AppAnimatedSplashState extends ConsumerState<AppAnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _logo;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  _SplashPhase _phase = _SplashPhase.logo;
  bool _seeded = false;
  bool _requestCategoryExit = false;
  bool _pendingExitAfterLogo = false;
  bool _exitStarted = false;
  bool _notifiedHomeUnderlay = false;
  bool _notifiedExitComplete = false;
  bool _assetsWarmed = false;

  @override
  void initState() {
    super.initState();

    _logo = AnimationController(
      vsync: this,
      duration: LoadingConstants.logoFade,
    );
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
    ]).animate(_logo);
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: LoadingConstants.logoScaleBegin,
          end: LoadingConstants.logoScaleEnd,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: LoadingConstants.logoScaleEnd, end: 1.02)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 35,
      ),
    ]).animate(_logo);

    _logo.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _startCategories();
    });

    // Precache on first frame, then start logo — same yellow surface, no gap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_warmThenStartLogo());
    });
  }

  Future<void> _warmThenStartLogo() async {
    await _precacheStartupAssets();
    if (!mounted) return;
    if (widget.appReady) {
      // Already ready (warm start) — skip logo, go straight to categories
      // so exit can finish one cycle quickly without a blank hold.
      _startCategories(requestExitIfReady: true);
      return;
    }
    _logo.forward(from: 0);
  }

  Future<void> _precacheStartupAssets() async {
    if (_assetsWarmed || !mounted) return;
    _assetsWarmed = true;
    try {
      await Future.wait<void>([
        precacheImage(
          const AssetImage(LoadingConstants.logoAsset),
          context,
        ),
        LoadingManager.boot(context: context),
      ]);
      // Warm first few category assets into ImageCache before they appear.
      if (mounted) {
        await LoadingService.precacheFirst(context);
      }
    } catch (_) {}
  }

  void _startCategories({bool requestExitIfReady = false}) {
    if (!mounted) return;
    if (_phase == _SplashPhase.categories) {
      if ((requestExitIfReady || _pendingExitAfterLogo) && widget.appReady) {
        _onAppBecameReady();
      }
      return;
    }
    final exitNow =
        _pendingExitAfterLogo || (requestExitIfReady && widget.appReady);
    setState(() {
      _phase = _SplashPhase.categories;
      if (exitNow) {
        _requestCategoryExit = true;
        _pendingExitAfterLogo = false;
      }
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
    if (_exitStarted) return;
    if (_phase != _SplashPhase.categories) {
      _pendingExitAfterLogo = true;
      return;
    }
    if (!_requestCategoryExit) {
      setState(() => _requestCategoryExit = true);
    }
  }

  /// Category cycle finished after [appReady] — reveal Home without page fade.
  void _onCategoryExitReady() {
    if (_exitStarted || !mounted) return;
    _exitStarted = true;

    if (!_notifiedHomeUnderlay) {
      _notifiedHomeUnderlay = true;
      widget.onReadyToOpenHome?.call();
    }

    // Wait until Home has painted (frame sync — no Timer / delayed).
    _afterFrames(2, () {
      if (!mounted || _notifiedExitComplete) return;
      _notifiedExitComplete = true;
      widget.onExitComplete?.call();
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
    _logo.dispose();
    super.dispose();
  }

  void _seed(List<CategoryModel> cats) {
    if (_seeded || cats.isEmpty) return;
    LoadingManager.seed(cats);
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      appBootstrapProvider.select((s) => s.homeSnapshot.categories),
      (prev, next) {
        if (next.isNotEmpty) {
          LoadingManager.seed(next);
          _seeded = true;
          if (mounted) unawaited(LoadingManager.boot(context: context));
        }
      },
    );

    final categories = ref.watch(
      appBootstrapProvider.select((s) => s.homeSnapshot.categories),
    );
    _seed(categories);

    // If ready while logo still playing, mark exit for the first category cycle.
    if (widget.appReady &&
        _phase == _SplashPhase.categories &&
        !_requestCategoryExit &&
        !_exitStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAppBecameReady();
      });
    }

    const bg = kLaunchYellow;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
            const HomeFeedWarmup(),
            if (_phase == _SplashPhase.logo)
              _LogoPhase(
                opacity: _logoOpacity,
                scale: _logoScale,
              )
            else
              CategoryLoadingWidget(
                compact: false,
                fullScreen: true,
                playing: true,
                requestExit: _requestCategoryExit,
                style: const CategoryLoadingStyle(
                  cycleDuration: LoadingConstants.categoryCycle,
                  background: bg,
                ),
                onExitReady: _onCategoryExitReady,
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoPhase extends StatelessWidget {
  const _LogoPhase({
    required this.opacity,
    required this.scale,
  });

  final Animation<double> opacity;
  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([opacity, scale]),
          builder: (context, child) {
            return Opacity(
              opacity: opacity.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale.value,
                child: child,
              ),
            );
          },
          child: Image.asset(
            LoadingConstants.logoAsset,
            width: 168,
            height: 168,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 168,
              height: 168,
            ),
          ),
        ),
      ),
    );
  }
}
