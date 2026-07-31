import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';

/// Fixed-slot home section: shimmer while loading, content fades in when ready.
///
/// Keeps [minHeight] reserved so the scroll layout does not jump. Never shows
/// a full-page loader or the startup category animation.
class HomeSectionSlot extends StatefulWidget {
  const HomeSectionSlot({
    super.key,
    required this.loading,
    required this.shimmer,
    required this.child,
    this.minHeight,
    this.fadeDuration = AppMotion.medium,
    this.hideWhenEmpty = false,
    this.isEmpty = false,
  });

  /// True while this section's own data is still loading.
  final bool loading;

  /// Lightweight in-flow placeholder (must approximate content size).
  final Widget shimmer;

  /// Real section content (ignored while [loading] or when empty+hide).
  final Widget child;

  /// Optional reserved height to prevent layout shift (banner/rail).
  final double? minHeight;

  final Duration fadeDuration;

  /// When true and [isEmpty], collapse to zero height after load.
  final bool hideWhenEmpty;
  final bool isEmpty;

  @override
  State<HomeSectionSlot> createState() => _HomeSectionSlotState();
}

class _HomeSectionSlotState extends State<HomeSectionSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;
  bool _showingContent = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: widget.fadeDuration);
    _opacity = CurvedAnimation(parent: _fade, curve: AppMotion.standard);
    _sync(immediate: true);
  }

  @override
  void didUpdateWidget(covariant HomeSectionSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ignore child identity — parents rebuild often with new Element trees.
    // Only loading / empty transitions should drive the fade controller.
    if (oldWidget.loading != widget.loading ||
        oldWidget.isEmpty != widget.isEmpty) {
      _sync(immediate: false);
    }
  }

  void _sync({required bool immediate}) {
    final showContent =
        !widget.loading && !(widget.hideWhenEmpty && widget.isEmpty);
    if (showContent == _showingContent && !immediate) {
      return;
    }
    final wasShowing = _showingContent;
    _showingContent = showContent;
    if (!_showingContent) {
      _fade.value = 0;
      return;
    }
    if (immediate || wasShowing) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideWhenEmpty && !widget.loading && widget.isEmpty) {
      return const SizedBox.shrink();
    }

    final body = widget.loading
        ? widget.shimmer
        : FadeTransition(
            opacity: _opacity,
            child: widget.child,
          );

    if (widget.minHeight == null) return body;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight!),
      child: body,
    );
  }
}
