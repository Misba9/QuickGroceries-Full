import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/model/maintenance_config_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/maintenance/ops/maintenance_ops_helpers.dart';

// ---------------------------------------------------------------------------
// Responsive metrics
// ---------------------------------------------------------------------------

/// Layout numbers for the preview strip (desktop sidebar + mobile bar).
class PreviewPanelMetrics {
  const PreviewPanelMetrics({
    required this.panelHeight,
    required this.cardWidth,
    required this.cardHeight,
    required this.useHorizontalScroll,
  });

  final double panelHeight;
  final double cardWidth;
  final double cardHeight;
  final bool useHorizontalScroll;

  static const double panelHeightDefault = 300;
  static const double cardHeightDefault = 272;
  static const double cardWidthMin = 128;
  static const double cardWidthMax = 140;
  static const double cardGap = 10;

  /// Three cards + gaps at minimum width without squeezing.
  static const double desktopRowMinWidth = cardWidthMin * 3 + cardGap * 2;

  factory PreviewPanelMetrics.fromMaxWidth(double maxWidth) {
    const panelHeight = panelHeightDefault;
    const cardHeight = cardHeightDefault;

    if (maxWidth >= desktopRowMinWidth) {
      final cardWidth = ((maxWidth - cardGap * 2) / 3)
          .clamp(cardWidthMin, cardWidthMax);
      return PreviewPanelMetrics(
        panelHeight: panelHeight,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        useHorizontalScroll: false,
      );
    }

    return const PreviewPanelMetrics(
      panelHeight: panelHeight,
      cardWidth: cardWidthMin,
      cardHeight: cardHeight,
      useHorizontalScroll: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Panel
// ---------------------------------------------------------------------------

/// Live phone-frame preview of customer / vendor / driver experiences.
class OpsPreviewPanel extends StatelessWidget {
  const OpsPreviewPanel({
    super.key,
    required this.config,
    required this.ops,
    this.compact = false,
  });

  final MaintenanceConfigModel config;
  final MaintenanceOpsSnapshot ops;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PanelTitleRow(theme: config.theme),
        const SizedBox(height: 10),
        if (compact)
          OpsPreviewCompactPhone(config: config, ops: ops)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = PreviewPanelMetrics.fromMaxWidth(
                constraints.maxWidth,
              );
              return SizedBox(
                height: metrics.panelHeight,
                child: _PreviewCardsStrip(
                  metrics: metrics,
                  cards: [
                    PreviewCard(
                      width: metrics.cardWidth,
                      height: metrics.cardHeight,
                      title: 'User app',
                      status: ops.userApp,
                      body: _UserPreviewBody(config: config, ops: ops),
                    ),
                    PreviewCard(
                      width: metrics.cardWidth,
                      height: metrics.cardHeight,
                      title: 'Vendor app',
                      status: ops.vendorApp,
                      body: _VendorPreviewBody(
                        config: config,
                        status: ops.vendorApp,
                      ),
                    ),
                    PreviewCard(
                      width: metrics.cardWidth,
                      height: metrics.cardHeight,
                      title: 'Driver app',
                      status: ops.driverApp,
                      body: _DriverPreviewBody(status: ops.driverApp),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PanelTitleRow extends StatelessWidget {
  const _PanelTitleRow({required this.theme});
  final String theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.phone_iphone_rounded, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Live app preview',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _ThemeChip(theme: theme),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme});
  final String theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        theme == 'dark' ? 'Dark' : 'Light',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PreviewCardsStrip extends StatelessWidget {
  const _PreviewCardsStrip({
    required this.metrics,
    required this.cards,
  });

  final PreviewPanelMetrics metrics;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: PreviewPanelMetrics.cardGap),
          cards[i],
        ],
      ],
    );

    if (metrics.useHorizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: row,
      );
    }

    return Align(alignment: Alignment.topLeft, child: row);
  }
}

// ---------------------------------------------------------------------------
// Preview card (reusable, overflow-safe)
// ---------------------------------------------------------------------------

/// Mini mobile preview card with fixed outer size and flexible inner body.
class PreviewCard extends StatelessWidget {
  const PreviewCard({
    super.key,
    required this.width,
    required this.height,
    required this.title,
    required this.status,
    required this.body,
  });

  final double width;
  final double height;
  final String title;
  final OpsChipStatus status;
  final Widget body;

  static const double _headerHeight = 34;
  static const double _paddingH = 8;
  static const double _paddingTop = 7;
  static const double _paddingBottom = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              _paddingH,
              _paddingTop,
              _paddingH,
              _paddingBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: _headerHeight,
                  child: _PreviewCardHeader(title: title, status: status),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-line header (title + status dot + label) — fits fixed 34px height.
class _PreviewCardHeader extends StatelessWidget {
  const _PreviewCardHeader({
    required this.title,
    required this.status,
  });

  final String title;
  final OpsChipStatus status;

  @override
  Widget build(BuildContext context) {
    final c = opsLevelColor(status.level);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: c,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact single-phone mode (mobile bar)
// ---------------------------------------------------------------------------

class OpsPreviewCompactPhone extends StatelessWidget {
  const OpsPreviewCompactPhone({
    super.key,
    required this.config,
    required this.ops,
  });

  final MaintenanceConfigModel config;
  final MaintenanceOpsSnapshot ops;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: _PhoneFrame(
        child: _UserPreviewBody(config: config, ops: ops),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mini app bodies (Expanded icon area + footer texts)
// ---------------------------------------------------------------------------

class _MiniAppBody extends StatelessWidget {
  const _MiniAppBody({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.footer,
    this.background,
    this.titleColor,
    this.subtitleColor,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? footer;
  final Widget? background;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Center(
            child: Icon(icon, size: 22, color: iconColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 7,
            height: 1,
            color: subtitleColor ?? Colors.grey.shade700,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 4),
          Text(
            footer!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 7,
              height: 1,
              color: Colors.grey.shade500,
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );

    if (background != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          background!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: content,
          ),
        ],
      );
    }

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }
}

class _UserPreviewBody extends StatelessWidget {
  const _UserPreviewBody({required this.config, required this.ops});
  final MaintenanceConfigModel config;
  final MaintenanceOpsSnapshot ops;

  @override
  Widget build(BuildContext context) {
    final isDark = config.theme == 'dark';
    final blocked = config.enabled && config.affectedUserApp;
    final gradient = isDark
        ? [const Color(0xFF0D0D0D), const Color(0xFF1A1A2E)]
        : [AppColor.primary, const Color(0xFFFFF8E7)];
    final fg = isDark ? Colors.white : Colors.black87;

    return _MiniAppBody(
      icon: blocked ? Icons.engineering_rounded : Icons.storefront_rounded,
      iconColor: fg.withValues(alpha: 0.9),
      title: blocked ? config.title.en : 'Quick Groceries',
      subtitle: blocked ? config.subtitle.en : 'Shop & checkout active',
      footer: ops.userApp.label,
      titleColor: fg,
      subtitleColor: fg.withValues(alpha: 0.75),
      background: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VendorPreviewBody extends StatelessWidget {
  const _VendorPreviewBody({required this.config, required this.status});
  final MaintenanceConfigModel config;
  final OpsChipStatus status;

  @override
  Widget build(BuildContext context) {
    final blocked = config.enabled && config.affectedVendorApp;
    return _MiniAppBody(
      icon: Icons.store_mall_directory_outlined,
      iconColor: opsLevelColor(status.level),
      title: blocked ? 'Vendor paused' : 'Orders live',
      subtitle: status.detail,
      footer: status.label,
    );
  }
}

class _DriverPreviewBody extends StatelessWidget {
  const _DriverPreviewBody({required this.status});
  final OpsChipStatus status;

  @override
  Widget build(BuildContext context) {
    final offline = status.level == OpsLevel.critical;
    return _MiniAppBody(
      icon: Icons.delivery_dining_rounded,
      iconColor: opsLevelColor(status.level),
      title: offline ? 'Unavailable' : 'On duty',
      subtitle: status.detail,
      footer: status.label,
    );
  }
}

/// Status dot for other ops dashboard widgets (header chips, etc.).
class OpsStatusDot extends StatelessWidget {
  const OpsStatusDot({super.key, required this.status, this.compact = false});
  final OpsChipStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = opsLevelColor(status.level);
    return SizedBox(
      height: compact ? 14 : 18,
      child: Row(
        children: [
          Container(
            width: compact ? 7 : 10,
            height: compact ? 7 : 10,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: compact ? 9 : 12,
                fontWeight: FontWeight.w800,
                color: c,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
