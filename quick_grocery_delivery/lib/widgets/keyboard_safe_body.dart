import 'package:flutter/material.dart';

/// Scrollable body that avoids RenderFlex overflow on small screens,
/// with keyboard open, or in landscape.
class KeyboardSafeBody extends StatelessWidget {
  const KeyboardSafeBody({
    super.key,
    required this.child,
    this.padding,
    this.fillMinHeight = false,
    this.centerWhenFilling = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool fillMinHeight;
  final bool centerWhenFilling;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final base = padding ?? EdgeInsets.zero;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = fillMinHeight
            ? (constraints.maxHeight - viewInsets.bottom)
                .clamp(0.0, double.infinity)
            : 0.0;

        Widget content = child;
        if (fillMinHeight && minHeight > 0) {
          content = ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: centerWhenFilling
                ? Align(alignment: Alignment.center, child: child)
                : child,
          );
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: base.add(EdgeInsets.only(bottom: viewInsets.bottom + 16)),
          child: content,
        );
      },
    );
  }
}
