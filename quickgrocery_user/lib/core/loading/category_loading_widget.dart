import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/loading/category_animation_controller.dart';
import 'package:quickgrocery/core/loading/category_loader.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/loading/loading_manager.dart';
import 'package:quickgrocery/core/loading/loading_theme.dart';

/// Premium one-by-one category loader (Blinkit-style).
///
/// Fade in → scale → hold → slide up → fade out → next.
/// No loading text, dots, shimmer, or spinner.
class CategoryLoadingWidget extends StatefulWidget {
  const CategoryLoadingWidget({
    super.key,
    this.compact = false,
    this.micro = false,
    this.fullScreen = false,
    this.style = const CategoryLoadingStyle(),
    this.semanticsLabel = 'Loading groceries',
    this.requestExit = false,
    this.onExitReady,
    this.playing = true,
  });

  final bool compact;
  final bool micro;
  final bool fullScreen;
  final CategoryLoadingStyle style;
  final String semanticsLabel;
  final bool requestExit;
  final VoidCallback? onExitReady;
  final bool playing;

  @override
  State<CategoryLoadingWidget> createState() => _CategoryLoadingWidgetState();
}

class _CategoryLoadingWidgetState extends State<CategoryLoadingWidget>
    with TickerProviderStateMixin {
  late final CategoryAnimationController _engine;
  late final AnimationController _cycle;
  late final AnimationController _float;
  late CategoryLoaderItem _current;

  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _engine = CategoryAnimationController()..reshuffle();
    _current = _engine.next();

    final period = widget.micro
        ? const Duration(milliseconds: 900)
        : (widget.style.cycleDuration ?? LoadingConstants.categoryCycle);

    _cycle = AnimationController(vsync: this, duration: period);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Exact thirds of 360ms: fade in 120 → hold 120 → fade/slide out 120.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 1,
      ),
    ]).animate(_cycle);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 1,
      ),
    ]).animate(_cycle);

    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.22))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 1,
      ),
    ]).animate(_cycle);

    _cycle.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      if (widget.requestExit) {
        widget.onExitReady?.call();
        return;
      }
      if (!widget.playing) return;
      setState(() => _current = _engine.next());
      _cycle.forward(from: 0);
    });

    // Start on the next frame after layout — keeps 60 FPS and avoids a blank
    // first paint before images are in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(LoadingManager.boot(context: context));
      if (widget.playing) {
        _cycle.forward(from: 0);
      } else {
        _cycle.value = 0;
      }
    });
  }

  @override
  void didUpdateWidget(covariant CategoryLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !oldWidget.playing) {
      _cycle.forward(from: 0);
    }
    if (widget.requestExit &&
        !oldWidget.requestExit &&
        !_cycle.isAnimating &&
        _cycle.status == AnimationStatus.completed) {
      widget.onExitReady?.call();
    }
  }

  @override
  void dispose() {
    _cycle.dispose();
    _float.dispose();
    super.dispose();
  }

  double get _imageSize {
    if (widget.micro) return LoadingConstants.imageSizeMicro;
    if (widget.compact) return LoadingConstants.imageSizeCompact;
    return LoadingConstants.imageSizeFull;
  }

  @override
  Widget build(BuildContext context) {
    final theme = LoadingTheme.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);

    final animated = reduce
        ? _CategoryBlock(
            item: _current,
            size: _imageSize,
            theme: theme,
            compact: widget.compact || widget.micro,
            showName: !widget.micro,
            reduceMotion: true,
            float: _float,
          )
        : AnimatedBuilder(
            animation: Listenable.merge([_cycle, _float]),
            builder: (context, _) {
              return FadeTransition(
                opacity: _opacity,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: _CategoryBlock(
                      item: _current,
                      size: _imageSize,
                      theme: theme,
                      compact: widget.compact || widget.micro,
                      showName: !widget.micro,
                      reduceMotion: false,
                      float: _float,
                    ),
                  ),
                ),
              );
            },
          );

    if (widget.micro) {
      return Semantics(
        label: widget.semanticsLabel,
        child: SizedBox(
          width: _imageSize + 4,
          height: _imageSize + 4,
          child: animated,
        ),
      );
    }

    final body = Semantics(
      liveRegion: true,
      label: '${widget.semanticsLabel}. ${_current.name}',
      child: animated,
    );

    if (!widget.fullScreen) return body;

    return SizedBox.expand(
      child: ColoredBox(
        color: widget.style.background ?? theme.background,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: theme.ambientGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.item,
    required this.size,
    required this.theme,
    required this.compact,
    required this.showName,
    required this.reduceMotion,
    required this.float,
  });

  final CategoryLoaderItem item;
  final double size;
  final LoadingTheme theme;
  final bool compact;
  final bool showName;
  final bool reduceMotion;
  final AnimationController float;

  @override
  Widget build(BuildContext context) {
    Widget orb = _CategoryOrb(
      item: item,
      size: size,
      theme: theme,
      reduceMotion: reduceMotion,
      float: float,
    );

    if (!showName) return orb;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orb,
        SizedBox(height: compact ? 12 : 18),
        Text(
          item.name,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: compact ? 15 : 22,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _CategoryOrb extends StatelessWidget {
  const _CategoryOrb({
    required this.item,
    required this.size,
    required this.theme,
    required this.reduceMotion,
    required this.float,
  });

  final CategoryLoaderItem item;
  final double size;
  final LoadingTheme theme;
  final bool reduceMotion;
  final AnimationController float;

  @override
  Widget build(BuildContext context) {
    Widget circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.card,
        boxShadow: size < 40 ? null : theme.shadow,
        border: Border.all(color: theme.imageRing, width: size < 40 ? 1 : 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(context),
    );

    if (reduceMotion) return circle;

    return AnimatedBuilder(
      animation: float,
      builder: (context, child) {
        final dy = math.sin(float.value * math.pi) * (size < 40 ? 1.5 : 5);
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: circle,
    );
  }

  Widget _buildImage(BuildContext context) {
    // No fade-in during splash — prevents image "pop" / flicker.
    const noFade = Duration.zero;
    if (item.hasNetworkImage) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        fadeInDuration: noFade,
        fadeOutDuration: noFade,
        placeholder: (_, __) =>
            _FallbackGlyph(item: item, size: size, theme: theme),
        errorWidget: (_, __, ___) =>
            _FallbackGlyph(item: item, size: size, theme: theme),
        useOldImageOnUrlChange: true,
      );
    }
    if (item.hasAsset) {
      return Image.asset(
        item.assetPath!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) =>
            _FallbackGlyph(item: item, size: size, theme: theme),
      );
    }
    return _FallbackGlyph(item: item, size: size, theme: theme);
  }
}

class _FallbackGlyph extends StatelessWidget {
  const _FallbackGlyph({
    required this.item,
    required this.size,
    required this.theme,
  });

  final CategoryLoaderItem item;
  final double size;
  final LoadingTheme theme;

  @override
  Widget build(BuildContext context) {
    final emoji = item.emoji;
    if (emoji != null && emoji.isNotEmpty) {
      return Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.42)),
      );
    }
    final letter = item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';
    return ColoredBox(
      color: theme.accent.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: theme.accent,
          ),
        ),
      ),
    );
  }
}
