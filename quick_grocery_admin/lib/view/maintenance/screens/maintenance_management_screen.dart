import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/view/maintenance/services/maintenance_management_service.dart';
import 'package:quick_grocery_admin/view/maintenance/widgets/maintenance_tab_views.dart';
import 'package:quick_grocery_admin/view/maintenance/widgets/ops_dashboard_widgets.dart';
import 'package:quick_grocery_admin/view/maintenance/widgets/ops_preview_panel.dart';

/// Operations Control Center — maintenance & availability (Blinkit/Zepto style).
class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() =>
      _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState
    extends State<MaintenanceManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  MaintenanceManagementService? _svc;

  static const _tabMeta = <(IconData, String)>[
    (Icons.podcasts_rounded, 'Live Status'),
    (Icons.tune_rounded, 'Maintenance'),
    (Icons.store_rounded, 'Store Hours'),
    (Icons.map_rounded, 'Delivery Areas'),
    (Icons.palette_rounded, 'Experience'),
    (Icons.history_rounded, 'Audit Logs'),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _tabMeta.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _svc = context.read<MaintenanceManagementService>();
      _svc!.attachUi();
      _svc!.ensureDocument();
    });
  }

  @override
  void dispose() {
    _svc?.detachUi();
    _tabs.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final svc = context.read<MaintenanceManagementService>();
    if (!svc.isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text(
          'You have ${svc.dirtyChangeCount} unpublished change(s). '
          'Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<MaintenanceManagementService>();

    return PopScope(
      canPop: !svc.isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _onWillPop();
        if (leave && context.mounted) Navigator.of(context).pop();
      },
      child: ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OpsLiveHeader(svc: svc),
            OpsDirtyBar(svc: svc),
            if (svc.error != null)
              Material(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    svc.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            Expanded(
              child: svc.loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide =
                            constraints.maxWidth >= AdminBreakpoints.desktop;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _OpsTabBar(
                                    controller: _tabs,
                                    meta: _tabMeta,
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabs,
                                      children: [
                                        MaintenanceLiveStatusTab(svc: svc),
                                        MaintenanceControlsTab(svc: svc),
                                        StoreAvailabilityTab(svc: svc),
                                        DeliveryAreasTab(svc: svc),
                                        CustomerExperienceTab(svc: svc),
                                        AuditLogsTab(svc: svc),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isWide)
                              SizedBox(
                                width: 420,
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: OpsPreviewPanel(
                                      config: svc.previewConfig,
                                      ops: svc.opsSnapshot,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
            if (!svc.loading &&
                MediaQuery.sizeOf(context).width <
                    AdminBreakpoints.desktop)
              SizedBox(
                height: 300,
                child: ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: OpsPreviewPanel(
                      config: svc.previewConfig,
                      ops: svc.opsSnapshot,
                      compact: true,
                    ),
                  ),
                ),
              ),
            OpsSaveFooter(svc: svc),
          ],
        ),
      ),
    );
  }
}

class _OpsTabBar extends StatelessWidget {
  const _OpsTabBar({required this.controller, required this.meta});
  final TabController controller;
  final List<(IconData, String)> meta;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFffde59),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          splashFactory: InkRipple.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFFffde59).withValues(alpha: 0.14);
            }
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFffde59).withValues(alpha: 0.22);
            }
            return null;
          }),
          tabs: [
            for (var i = 0; i < meta.length; i++)
              Tab(
                height: 44,
                child: _OpsTabLabel(
                  controller: controller,
                  index: i,
                  icon: meta[i].$1,
                  label: meta[i].$2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpsTabLabel extends StatefulWidget {
  const _OpsTabLabel({
    required this.controller,
    required this.index,
    required this.icon,
    required this.label,
  });

  final TabController controller;
  final int index;
  final IconData icon;
  final String label;

  @override
  State<_OpsTabLabel> createState() => _OpsTabLabelState();
}

class _OpsTabLabelState extends State<_OpsTabLabel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(_OpsTabLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.controller.index == widget.index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            widget.controller.animateTo(widget.index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
            Icon(
              widget.icon,
              size: 18,
              color: isSelected ? Colors.black87 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
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
