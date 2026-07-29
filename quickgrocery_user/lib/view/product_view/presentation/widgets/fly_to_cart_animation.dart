import 'package:flutter/material.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Lightweight "fly-to-cart" effect.
///
/// Pops an [OverlayEntry] that animates a circular thumbnail from
/// [startRect] toward the top-right of the current screen (where the cart
/// icon typically lives) while shrinking and fading. The overlay disposes
/// itself when the animation completes.
class FlyToCart {
  const FlyToCart._();

  static Future<void> run(
    BuildContext context, {
    required String imageUrl,
    required Rect startRect,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final size = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top;

    // End position: roughly where an AppBar trailing icon sits.
    final endRect = Rect.fromLTWH(
      size.width - 60,
      paddingTop + 8,
      30,
      30,
    );

    final entry = OverlayEntry(
      builder: (_) => _FlyingThumb(
        imageUrl: imageUrl,
        startRect: startRect,
        endRect: endRect,
      ),
    );
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 720));
    entry.remove();
    entry.dispose();
  }
}

class _FlyingThumb extends StatefulWidget {
  const _FlyingThumb({
    required this.imageUrl,
    required this.startRect,
    required this.endRect,
  });

  final String imageUrl;
  final Rect startRect;
  final Rect endRect;

  @override
  State<_FlyingThumb> createState() => _FlyingThumbState();
}

class _FlyingThumbState extends State<_FlyingThumb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (_, __) {
        // Quadratic bezier-style arc for a more "thrown-up" feel.
        final t = _t.value;
        final dx = _lerp(widget.startRect.left, widget.endRect.left, t);
        final dyLinear = _lerp(widget.startRect.top, widget.endRect.top, t);
        // Subtle arc: pull up by 60px at midpoint.
        final arc = -60 * 4 * t * (1 - t);
        final dy = dyLinear + arc;
        final sz = _lerp(widget.startRect.width, widget.endRect.width, t);
        final opacity = (1 - t).clamp(0.0, 1.0);

        return Positioned(
          left: dx,
          top: dy,
          width: sz,
          height: sz,
          child: Opacity(
            opacity: opacity,
            child: ClipOval(
              child: CachedImage(url: widget.imageUrl, fit: BoxFit.cover),
            ),
          ),
        );
      },
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}
