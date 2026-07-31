import 'package:flutter/material.dart';

import '../design/app_tokens.dart';

/// Cheap staggered fade+slide-in for list / rail children.
///
/// Uses a single [AnimationController] with an [Interval] — no [Future.delayed]
/// or [Timer], so the UI thread stays free for 60 FPS scrolling.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.perItemDelay = const Duration(milliseconds: 32),
    this.duration = AppMotion.short,
    this.offset = const Offset(0, 0.05),
  });

  final Widget child;
  final int index;
  final Duration perItemDelay;
  final Duration duration;
  final Offset offset;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final staggerMs = widget.perItemDelay.inMilliseconds * widget.index;
    final totalMs = widget.duration.inMilliseconds + staggerMs;
    final start = (staggerMs / totalMs).clamp(0.0, 0.85);

    _ctl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _fade = CurvedAnimation(
      parent: _ctl,
      curve: Interval(start, 1, curve: AppMotion.emphasized),
    );
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _ctl,
        curve: Interval(start, 1, curve: AppMotion.emphasized),
      ),
    );
    _ctl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_done) {
        setState(() => _done = true);
      }
    });
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // After the intro animation, drop tickers so parent rebuilds are cheap.
    if (_done) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
