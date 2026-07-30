import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/constants/home_branding.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading.dart';
import 'package:quickgrocery/core/startup/app_bootstrap_controller.dart';

/// Blinkit-style branded cold-start splash with grocery category energy.
class AppAnimatedSplash extends ConsumerStatefulWidget {
  const AppAnimatedSplash({super.key});

  @override
  ConsumerState<AppAnimatedSplash> createState() => _AppAnimatedSplashState();
}

class _AppAnimatedSplashState extends ConsumerState<AppAnimatedSplash>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _float;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _taglineSlide;

  late final LoadingRandom _rng;
  late LoadingMoment _moment;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _rng = LoadingRandom();
    _moment = LoadingMoment.fresh(_rng);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
    );
    _intro.forward();

    unawaited(LoadingAssets.warmUp());

    _messageTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) return;
      setState(() {
        final cat = _rng.nextCategory();
        _moment = LoadingMoment(
          category: cat,
          message: _rng.nextStatusLine(category: cat),
          emoji: cat.emoji,
        );
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _intro.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final controllerMessage = bootstrap.loadingMessage.trim();
    final statusLine =
        controllerMessage.isNotEmpty ? controllerMessage : _moment.message;
    final progress = bootstrap.progress.clamp(0.0, 1.0);
    final surface = AppSurface.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColor.primary.withValues(alpha: context.isDarkTheme ? 0.16 : 0.18),
              surface.scaffold,
              surface.scaffold,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: surface.card,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppShadow.primaryGlow,
                        border: Border.all(
                          color: surface.border.withValues(alpha: 0.6),
                        ),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) {
                    final dy = reduceMotion
                        ? 0.0
                        : math.sin(_float.value * math.pi) * 5;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: child,
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: kLoadingSwitchDuration,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Text(
                      _moment.emoji,
                      key: ValueKey(_moment.emoji),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Column(
                      children: [
                        Text(
                          'QuickGrocery',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: surface.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          HomeBranding.tagline,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: surface.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    statusLine,
                    key: ValueKey<String>(statusLine),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: surface.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _moment.category.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: surface.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    minHeight: 4,
                    backgroundColor: AppColor.primary.withValues(alpha: 0.12),
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
