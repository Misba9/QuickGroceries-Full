import 'package:flutter/material.dart';

/// Scroll-safe orders page body (no [Expanded] / [Spacer]).
///
/// Vertical scroll is provided by [AdminSafePage] in [AdminPageSlot]; this widget
/// only constrains width and lays out a shrink-wrapped [Column].
class OrdersSafeContent extends StatelessWidget {
  const OrdersSafeContent({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: maxW,
            maxWidth: maxW,
          ),
          child: child,
        );
      },
    );
  }
}

/// Orders page background tint.
class OrdersPageShell extends StatelessWidget {
  const OrdersPageShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: OrdersSafeContent(child: child),
    );
  }
}
