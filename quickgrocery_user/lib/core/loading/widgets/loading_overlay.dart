import 'dart:async';

import 'package:flutter/material.dart';

import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/loading/loading_controller.dart';
import 'package:quickgrocery/core/loading/widgets/animated_category_loader.dart';

/// Gates child visibility for at least [minDisplay] to avoid flash.
class MinLoadingGate extends StatefulWidget {
  const MinLoadingGate({
    super.key,
    required this.loading,
    required this.loadingBuilder,
    required this.child,
    this.minDisplay = const Duration(milliseconds: kMinLoadingDisplayMs),
  });

  final bool loading;
  final WidgetBuilder loadingBuilder;
  final Widget child;
  final Duration minDisplay;

  @override
  State<MinLoadingGate> createState() => _MinLoadingGateState();
}

class _MinLoadingGateState extends State<MinLoadingGate> {
  bool _showLoading = false;
  DateTime? _startedAt;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (widget.loading) _start();
  }

  @override
  void didUpdateWidget(covariant MinLoadingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !oldWidget.loading) {
      _start();
    } else if (!widget.loading && oldWidget.loading) {
      _scheduleHide();
    }
  }

  void _start() {
    _hideTimer?.cancel();
    _startedAt = DateTime.now();
    if (!_showLoading) setState(() => _showLoading = true);
  }

  void _scheduleHide() {
    final started = _startedAt;
    if (started == null) {
      setState(() => _showLoading = false);
      return;
    }
    final elapsed = DateTime.now().difference(started);
    final remaining = widget.minDisplay - elapsed;
    if (remaining <= Duration.zero) {
      if (_showLoading) setState(() => _showLoading = false);
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(remaining, () {
      if (!mounted) return;
      setState(() => _showLoading = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showLoading
          ? KeyedSubtree(
              key: const ValueKey('loading'),
              child: widget.loadingBuilder(context),
            )
          : KeyedSubtree(
              key: const ValueKey('content'),
              child: widget.child,
            ),
    );
  }
}

/// Semi-transparent overlay with animated category loader.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
    this.messagePool,
  });

  final bool visible;
  final Widget child;
  final List<String>? messagePool;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppSurface.of(context)
                      .scaffold
                      .withValues(alpha: 0.72),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: AnimatedCategoryLoader(
                      compact: true,
                      messagePool: messagePool,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
