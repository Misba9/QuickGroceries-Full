import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/layout/admin_constraints.dart';

/// Standard scroll page body — use for forms, dashboards, orders (no [Scaffold] / [Expanded]).
class AdminSafePage extends StatelessWidget {
  const AdminSafePage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.debugLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && debugLabel != null) {
      debugPrint('AdminSafePage: $debugLabel');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;

        return SingleChildScrollView(
          primary: false,
          padding: padding,
          child: ConstrainedBox(
            constraints: adminNormalizedConstraints(viewportWidth: maxW),
            child: Align(
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Fills viewport height — child may use [Column] + [Expanded] + [ListView].
///
/// Must NOT nest another [LayoutBuilder] here: [AdminPageSlot] already sizes the
/// pane with a tight [SizedBox]. A second [LayoutBuilder] on Flutter Web causes
/// `!_debugDoingThisLayout` / "RenderBox has no size" when children rebuild
/// (e.g. [StreamBuilder]).
class AdminFlexPage extends StatelessWidget {
  const AdminFlexPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.debugLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? debugLabel;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && debugLabel != null) {
      debugPrint('AdminFlexPage: $debugLabel');
    }

    return Padding(
      padding: padding,
      child: child,
    );
  }
}
