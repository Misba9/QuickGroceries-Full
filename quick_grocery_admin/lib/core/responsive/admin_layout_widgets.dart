import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/responsive/admin_content_scope.dart';
import 'package:quick_grocery_admin/style/app_color.dart';

/// Prevents horizontal overflow for admin page roots (min-w-0 equivalent).
class AdminOverflowSafe extends StatelessWidget {
  const AdminOverflowSafe({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: AdminContentScope.contentWidth(context),
        child: child,
      ),
    );
  }
}

/// Scrollable admin body — use only on standalone routes, not inside [AdminPageWrapper].
@Deprecated('Prefer AdminPageSlot scroll; nested scroll causes infinite layout on web.')
class AdminScrollBody extends StatelessWidget {
  const AdminScrollBody({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 0,
              maxWidth: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : double.infinity,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// Stacks on narrow viewports; otherwise horizontal row with [Expanded] children.
class AdminResponsiveRow extends StatelessWidget {
  const AdminResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 720,
    this.spacing = 16,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final stacked = c.maxWidth < breakpoint;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced(children, spacing, vertical: true),
          );
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment == CrossAxisAlignment.stretch
              ? CrossAxisAlignment.start
              : crossAxisAlignment,
          children: children
              .map(
                (w) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: children.indexOf(w) < children.length - 1 ? spacing : 0,
                    ),
                    child: w,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<Widget> _spaced(List<Widget> items, double gap, {required bool vertical}) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(vertical ? SizedBox(height: gap) : SizedBox(width: gap));
      }
    }
    return out;
  }
}

/// 1 / 2 / 3 column responsive grid for form fields.
class AdminResponsiveGrid extends StatelessWidget {
  const AdminResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.spacing = 12,
    this.runSpacing = 12,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / minTileWidth).floor().clamp(1, 3);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: runSpacing,
          crossAxisSpacing: spacing,
          childAspectRatio: cols == 1 ? 3.2 : 2.8,
          children: children,
        );
      },
    );
  }
}

/// Full-width primary action — never fixed 300px.
class AdminPrimaryButton extends StatelessWidget {
  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : double.infinity;
        return SizedBox(
          width: w,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Responsive image / file upload block (aspect-ratio preview + full-width button).
class AdminUploadSection extends StatelessWidget {
  const AdminUploadSection({
    super.key,
    required this.label,
    required this.buttonLabel,
    required this.onTap,
    this.preview,
    this.aspectRatio = 1,
    this.maxPreviewSize = 140,
  });

  final String label;
  final String buttonLabel;
  final VoidCallback onTap;
  final Widget? preview;
  final double aspectRatio;
  final double maxPreviewSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final previewW = (c.maxWidth * 0.35).clamp(96.0, maxPreviewSize);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: previewW,
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: const Color(0xFFFAFAFB),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: preview ??
                        const Center(
                          child: Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.upload_file, size: 18),
                label: Text(
                  buttonLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Wraps form fields at a fraction of **content** width (not screen).
class AdminFieldBox extends StatelessWidget {
  const AdminFieldBox({
    super.key,
    required this.label,
    required this.child,
    this.widthFraction = 1,
  });

  final String label;
  final Widget child;
  final double widthFraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : AdminContentScope.contentWidth(context);
        final w = (parentW * widthFraction).clamp(0.0, parentW);

        return SizedBox(
          width: w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(height: 8),
              child,
            ],
          ),
        );
      },
    );
  }
}

/// Two-column admin form layout used across legacy screens.
class AdminLegacyFormSplit extends StatelessWidget {
  const AdminLegacyFormSplit({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 800,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: 20),
              right,
            ],
          );
        }
        final gap = 16.0;
        final colW = (c.maxWidth - gap) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: colW, child: left),
            SizedBox(width: gap),
            SizedBox(width: colW, child: right),
          ],
        );
      },
    );
  }
}

/// Constrains dialogs / bottom sheets on web admin.
class AdminDialogBody extends StatelessWidget {
  const AdminDialogBody({super.key, required this.child, this.maxWidth = 520});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: child,
    );
  }
}
