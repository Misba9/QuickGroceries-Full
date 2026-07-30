import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_controller.dart';
import 'package:quickgrocery/core/loading/loading_messages.dart';
import 'package:quickgrocery/core/loading/loading_random.dart';

/// Premium Blinkit-style category loader: bouncing emoji + rotating message.
class AnimatedCategoryLoader extends StatefulWidget {
  const AnimatedCategoryLoader({
    super.key,
    this.messagePool,
    this.compact = false,
    this.showCard = true,
    this.rotateEvery = const Duration(milliseconds: 2600),
    this.semanticsLabel = 'Loading',
  });

  final List<String>? messagePool;
  final bool compact;
  final bool showCard;
  final Duration rotateEvery;
  final String semanticsLabel;

  @override
  State<AnimatedCategoryLoader> createState() => _AnimatedCategoryLoaderState();
}

class _AnimatedCategoryLoaderState extends State<AnimatedCategoryLoader>
    with TickerProviderStateMixin {
  late final LoadingRandom _rng;
  late LoadingMoment _moment;
  late final AnimationController _bounce;
  late final AnimationController _float;
  late final AnimationController _spin;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _rng = LoadingRandom();
    _moment = LoadingMoment.fresh(_rng);
    if (widget.messagePool != null) {
      _moment = LoadingMoment(
        category: _moment.category,
        message: _rng.nextMessage(pool: widget.messagePool),
        emoji: _moment.emoji,
      );
    }

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _rotateTimer = Timer.periodic(widget.rotateEvery, (_) {
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      if (reduce) return;
      setState(() {
        final cat = _rng.nextCategory();
        _moment = LoadingMoment(
          category: cat,
          message: widget.messagePool != null
              ? _rng.nextMessage(pool: widget.messagePool)
              : _rng.nextStatusLine(category: cat),
          emoji: cat.emoji,
        );
      });
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _bounce.dispose();
    _float.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final emojiSize = widget.compact ? 36.0 : 52.0;

    Widget emoji = Text(
      _moment.emoji,
      style: TextStyle(fontSize: emojiSize),
    );

    if (!reduceMotion) {
      emoji = AnimatedBuilder(
        animation: Listenable.merge([_bounce, _float, _spin]),
        builder: (context, child) {
          final scale = 0.92 + (_bounce.value * 0.12);
          final dy = math.sin(_float.value * math.pi) * 6;
          final angle = (_spin.value - 0.5) * 0.12;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: emoji,
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.compact ? 72 : 96,
          height: widget.compact ? 72 : 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(widget.compact ? 20 : 28),
            boxShadow: AppShadow.dim,
          ),
          child: AnimatedSwitcher(
            duration: kLoadingSwitchDuration,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(_moment.category.id + _moment.emoji),
              child: emoji,
            ),
          ),
        ),
        SizedBox(height: widget.compact ? 12 : 18),
        AnimatedSwitcher(
          duration: kLoadingSwitchDuration,
          child: Text(
            _moment.message,
            key: ValueKey(_moment.message),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: widget.compact ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: surface.textSecondary,
            ),
          ),
        ),
        if (!widget.compact) ...[
          const SizedBox(height: 6),
          Text(
            _moment.category.label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: surface.textMuted,
            ),
          ),
        ],
      ],
    );

    final body = Semantics(
      liveRegion: true,
      label: '${widget.semanticsLabel}. ${_moment.message}',
      child: content,
    );

    if (!widget.showCard) return body;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: widget.compact ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: surface.card,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: surface.border.withValues(alpha: 0.7)),
        boxShadow: AppShadow.cardOf(context),
      ),
      child: body,
    );
  }
}

/// Compact row used above skeleton pages (home/cart/search).
class CategoryLoaderBanner extends StatelessWidget {
  const CategoryLoaderBanner({
    super.key,
    this.messagePool,
  });

  final List<String>? messagePool;

  @override
  Widget build(BuildContext context) {
    return AnimatedCategoryLoader(
      compact: true,
      showCard: true,
      messagePool: messagePool ?? LoadingMessages.friendly,
      rotateEvery: const Duration(milliseconds: 2400),
    );
  }
}

/// Full-screen branded loader (splash-adjacent pages).
class CategoryLoaderScreen extends StatelessWidget {
  const CategoryLoaderScreen({
    super.key,
    this.messagePool,
  });

  final List<String>? messagePool;

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface.of(context);
    return Scaffold(
      backgroundColor: surface.scaffold,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedCategoryLoader(
              messagePool: messagePool,
              showCard: false,
            ),
          ),
        ),
      ),
    );
  }
}
