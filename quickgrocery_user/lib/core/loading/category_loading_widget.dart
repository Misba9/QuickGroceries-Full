import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/core/loading/category_animation_controller.dart';
import 'package:quickgrocery/core/loading/category_loader.dart';
import 'package:quickgrocery/core/loading/loading_constants.dart';
import 'package:quickgrocery/core/loading/loading_manager.dart';
import 'package:quickgrocery/core/loading/loading_theme.dart';

/// Full-screen Blinkit/Zepto-style category beat for startup.
///
/// One large centered category: fade in → scale 0.95→1 → slight rise →
/// hold → fade out → next. No progress, logo, text chrome, or spinner.
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
    with SingleTickerProviderStateMixin {
  late final CategoryAnimationController _engine;
  late final AnimationController _cycle;
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

    // ~100ms in / ~280ms hold / ~90ms out of 470ms.
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: LoadingConstants.revealCurve)),
        weight: 21,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 19,
      ),
    ]).animate(_cycle);

    // Spec: slight scale 0.95 → 1.0.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: LoadingConstants.revealCurve)),
        weight: 21,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 19,
      ),
    ]).animate(_cycle);

    // Small upward movement — enter from below, exit slightly up.
    _slide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
            .chain(CurveTween(curve: LoadingConstants.revealCurve)),
        weight: 21,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(0, -0.06))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 19,
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
    final splashMode = widget.style.background != null;

    final animated = reduce
        ? _CategoryBlock(
            item: _current,
            size: _imageSize,
            theme: theme,
            compact: widget.compact || widget.micro,
            showName: !widget.micro,
            nameColor: widget.style.textColor,
            splashMode: splashMode,
          )
        : AnimatedBuilder(
            animation: _cycle,
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
                      nameColor: widget.style.textColor,
                      splashMode: splashMode,
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

    final bg = widget.style.background ?? theme.background;

    return SizedBox.expand(
      child: ColoredBox(
        color: bg,
        child: SafeArea(
          child: Center(
            child: Padding(
              // Plenty of white space — icon + title only.
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: body,
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
    this.nameColor,
    this.splashMode = false,
  });

  final CategoryLoaderItem item;
  final double size;
  final LoadingTheme theme;
  final bool compact;
  final bool showName;
  final Color? nameColor;
  final bool splashMode;

  @override
  Widget build(BuildContext context) {
    final orb = _CategoryOrb(
      item: item,
      size: size,
      theme: theme,
      splashMode: splashMode,
    );

    if (!showName) return orb;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        orb,
        SizedBox(height: compact ? 14 : 28),
        Text(
          item.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: compact ? 16 : 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: nameColor ?? theme.textPrimary,
            letterSpacing: -0.5,
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
    this.splashMode = false,
  });

  final CategoryLoaderItem item;
  final double size;
  final LoadingTheme theme;
  final bool splashMode;

  @override
  Widget build(BuildContext context) {
    // Soft white disc on yellow — minimal chrome, premium grocery feel.
    final shadows = size < 40
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: splashMode ? 0.07 : 0.10),
              blurRadius: splashMode ? 24 : 16,
              offset: const Offset(0, 8),
            ),
          ];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: splashMode ? Colors.white : theme.card,
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImage(context),
    );
  }

  Widget _buildImage(BuildContext context) {
    // No image fade during splash — avoids flicker mid-beat.
    if (item.hasNetworkImage) {
      final cacheW = (size * MediaQuery.devicePixelRatioOf(context)).round();
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        memCacheWidth: cacheW,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
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
      return ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
        ),
      );
    }
    final letter = item.name.isNotEmpty ? item.name[0].toUpperCase() : '?';
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
