import 'package:flutter/material.dart';

import '../design/app_tokens.dart';

/// Cheap, allocation-free staggered fade+slide-in for any child.
///
/// Used inside lists / rails so items don't all pop in at once. Pass
/// [index] to derive the per-item delay.
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.perItemDelay = const Duration(milliseconds: 40),
    this.duration = AppMotion.medium,
    this.offset = const Offset(0, 0.08),
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
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctl,
    curve: AppMotion.standard,
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.perItemDelay * widget.index, () {
      if (mounted) _ctl.forward();
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
