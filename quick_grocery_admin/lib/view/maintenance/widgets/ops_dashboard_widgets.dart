import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/maintenance/ops/maintenance_audit_entry.dart';
import 'package:quick_grocery_admin/view/maintenance/ops/maintenance_ops_helpers.dart';
import 'package:quick_grocery_admin/view/maintenance/services/maintenance_management_service.dart';

class OpsLiveHeader extends StatelessWidget {
  const OpsLiveHeader({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final ops = svc.opsSnapshot;
    final synced = svc.lastSyncedAt;
    final remote = svc.lastRemoteUpdateAt;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColor.primary,
                      AppColor.primary.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_rounded, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations Control Center',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Maintenance & availability · realtime',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _SyncBadge(svc: svc),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _OpsChip(title: 'STORE', status: ops.store, pulse: svc.livePulse),
              _OpsChip(title: 'ORDERING', status: ops.ordering, pulse: svc.livePulse),
              _OpsChip(title: 'USER APP', status: ops.userApp, pulse: svc.livePulse),
              _OpsChip(title: 'VENDOR', status: ops.vendorApp, pulse: svc.livePulse),
              _OpsChip(title: 'DRIVER', status: ops.driverApp, pulse: svc.livePulse),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Meta(
                icon: Icons.cloud_done_rounded,
                label: svc.firebaseConnected ? 'Firebase connected' : 'Disconnected',
                ok: svc.firebaseConnected,
              ),
              _Meta(
                icon: Icons.sync_rounded,
                label: synced != null
                    ? 'Published ${ _rel(synced)}'
                    : 'Not published this session',
                ok: synced != null,
              ),
              _Meta(
                icon: Icons.rss_feed_rounded,
                label: remote != null
                    ? 'Live feed ${_rel(remote)}'
                    : 'Waiting for feed…',
                ok: remote != null,
              ),
              if (svc.isDirty)
                _Meta(
                  icon: Icons.edit_note_rounded,
                  label: '${svc.dirtyChangeCount} pending change(s)',
                  ok: false,
                  warn: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _rel(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (svc.syncStatus) {
      MaintenanceSyncStatus.saving => (
          'Saving…',
          const Color(0xFFD97706),
          Icons.cloud_upload_rounded,
        ),
      MaintenanceSyncStatus.synced => (
          'Synced',
          const Color(0xFF16A34A),
          Icons.check_circle_rounded,
        ),
      MaintenanceSyncStatus.failed => (
          'Sync failed',
          const Color(0xFFDC2626),
          Icons.error_outline_rounded,
        ),
      MaintenanceSyncStatus.idle => (
          svc.isDirty ? 'Draft' : 'Live',
          svc.isDirty ? const Color(0xFFD97706) : const Color(0xFF64748B),
          svc.isDirty ? Icons.edit_rounded : Icons.podcasts_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsChip extends StatelessWidget {
  const _OpsChip({
    required this.title,
    required this.status,
    required this.pulse,
  });

  final String title;
  final OpsChipStatus status;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final c = opsLevelColor(status.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: opsLevelBackground(status.level),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: c, active: pulse),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                status.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.ok,
    this.warn = false,
  });

  final IconData icon;
  final String label;
  final bool ok;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn
        ? const Color(0xFFD97706)
        : ok
            ? const Color(0xFF16A34A)
            : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class OpsSystemStateCard extends StatelessWidget {
  const OpsSystemStateCard({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final lines = svc.opsSnapshot.activeSummary;
    return OpsGlassCard(
      title: 'Current system state',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColor.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => svc.updateConfig(
              svc.previewConfig.copyWith(enabled: !svc.previewConfig.enabled),
            ),
            icon: const Icon(Icons.science_outlined, size: 18),
            label: const Text('Test maintenance toggle (draft)'),
          ),
        ],
      ),
    );
  }
}

class OpsAppStatusCard extends StatelessWidget {
  const OpsAppStatusCard({
    required this.title,
    required this.icon,
    required this.status,
    required this.body,
    this.metric,
  });

  final String title;
  final IconData icon;
  final OpsChipStatus status;
  final String body;
  final String? metric;

  @override
  Widget build(BuildContext context) {
    final c = opsLevelColor(status.level);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: opsLevelBackground(status.level),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status.label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (metric != null) ...[
            const SizedBox(height: 10),
            Text(
              metric!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lightweight pulse — no flutter_animate (avoids disposed RenderObject on rebuild).
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, required this.active});
  final Color color;
  final bool active;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mounted) return;
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class OpsConnectionStrip extends StatelessWidget {
  const OpsConnectionStrip({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final ops = svc.opsSnapshot;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _Conn('Firebase', svc.firebaseConnected),
          _Conn('User app sync', ops.userApp.level != OpsLevel.critical),
          _Conn('Vendor sync', ops.vendorApp.level != OpsLevel.critical),
          _Conn(
            'Driver sync',
            ops.driverApp.level == OpsLevel.active,
          ),
        ],
      ),
    );
  }
}

class _Conn extends StatelessWidget {
  const _Conn(this.label, this.ok);
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: ok ? const Color(0xFF16A34A) : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class OpsDirtyBar extends StatelessWidget {
  const OpsDirtyBar({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    if (!svc.isDirty) return const SizedBox.shrink();
    return Material(
      elevation: 6,
      color: const Color(0xFFFFF7ED),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You have ${svc.dirtyChangeCount} unsaved change${svc.dirtyChangeCount == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: svc.saving
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Discard changes?'),
                          content: const Text(
                            'All unpublished edits will be lost.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Discard'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) svc.discardChanges();
                    },
              child: const Text('Discard'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: svc.saving ? null : () => _save(context),
              icon: svc.saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded, size: 18),
              label: Text(svc.saving ? 'Publishing…' : 'Save & publish'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final ok = await svc.save();
    if (!context.mounted) return;
    final msg = ok
        ? 'Synced successfully — all apps updated'
        : 'Sync failed — check connection';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
      ),
    );
  }
}

class OpsSaveFooter extends StatelessWidget {
  const OpsSaveFooter({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              svc.syncStatus == MaintenanceSyncStatus.synced && svc.lastSyncedAt != null
                  ? 'Last published ${_fmt(svc.lastSyncedAt!)}'
                  : 'Changes publish instantly to user, vendor & driver apps',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: !svc.isDirty || svc.saving ? null : svc.discardChanges,
            child: const Text('Discard'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: svc.saving ? null : () async {
              final ok = await svc.save();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? 'Published' : 'Failed')),
              );
            },
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text(svc.saving ? 'Publishing…' : 'Save & publish'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColor.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(160, 44),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return 'at $h:$m';
  }
}

class OpsAuditPanel extends StatelessWidget {
  const OpsAuditPanel({required this.svc});
  final MaintenanceManagementService svc;

  @override
  Widget build(BuildContext context) {
    final logs = svc.filteredAuditLogs;
    return OpsGlassCard(
      title: 'Audit log',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search activity…',
              isDense: true,
            ),
            onChanged: svc.setAuditFilter,
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No activity yet',
                style: GoogleFonts.poppins(color: Colors.grey.shade500),
              ),
            )
          else
            ...logs.map(
              (e) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AuditRow(entry: e),
                  if (e != logs.last)
                    Divider(color: Colors.grey.shade200),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});
  final MaintenanceAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(entry.action);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(_actionIcon(entry.action), size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.displayAction,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                _time(entry.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _actionColor(String a) {
    if (a.contains('emergency') || a.contains('stop')) return Colors.red;
    if (a.contains('save') || a.contains('publish')) return Colors.green;
    return Colors.blue;
  }

  IconData _actionIcon(String a) {
    if (a.contains('emergency')) return Icons.warning_rounded;
    if (a.contains('discard')) return Icons.undo_rounded;
    return Icons.edit_rounded;
  }

  String _time(DateTime? t) {
    if (t == null) return 'Just now';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class OpsGlassCard extends StatelessWidget {
  const OpsGlassCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class OpsFormField extends StatelessWidget {
  const OpsFormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.dirty = false,
    this.helper,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final bool dirty;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          filled: true,
          fillColor: dirty ? const Color(0xFFFFF7ED) : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: dirty ? const Color(0xFFD97706) : Colors.grey.shade300,
              width: dirty ? 1.5 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
