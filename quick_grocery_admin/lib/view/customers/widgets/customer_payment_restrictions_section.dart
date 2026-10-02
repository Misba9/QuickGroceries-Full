import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/customers/services/cod_restriction_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/widgets/cod_restriction_editor_dialog.dart';

/// Payment Restrictions card for the customer profile "User info" tab.
class CustomerPaymentRestrictionsSection extends StatefulWidget {
  const CustomerPaymentRestrictionsSection({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<CustomerPaymentRestrictionsSection> createState() =>
      _CustomerPaymentRestrictionsSectionState();
}

class _CustomerPaymentRestrictionsSectionState
    extends State<CustomerPaymentRestrictionsSection> {
  final _svc = CodRestrictionAdminService();
  bool _loading = true;
  String? _error;
  CodPaymentRestriction _restriction = CodPaymentRestriction.enabled;
  List<CodRestrictionHistoryEntry> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _svc.getForUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _restriction = result.restriction;
        _history = result.history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    final ok = await showCodRestrictionEditor(
      context: context,
      userId: widget.userId,
      userName: widget.userName,
      current: _restriction,
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y · HH:mm');
    final badge = _restriction.badge;

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment Restrictions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Manage COD'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red.shade700))
            else ...[
              _BadgeChip(badge: badge),
              const SizedBox(height: 14),
              _kv('Current Status', badge.label),
              _kv(
                'Restriction Type',
                _restriction.codRestrictionType.name,
              ),
              _kv(
                'Reason',
                _restriction.codRestrictionReason.isEmpty
                    ? '—'
                    : _restriction.codRestrictionReason,
              ),
              _kv(
                'Restricted By',
                _restriction.codRestrictedByName.isEmpty
                    ? '—'
                    : _restriction.codRestrictedByName,
              ),
              _kv(
                'Start Date',
                _restriction.codRestrictionStart == null
                    ? '—'
                    : fmt.format(_restriction.codRestrictionStart!),
              ),
              _kv(
                'End Date',
                _restriction.codRestrictionEnd == null
                    ? '—'
                    : fmt.format(_restriction.codRestrictionEnd!),
              ),
              _kv(
                'Last Updated',
                _restriction.codUpdatedAt == null
                    ? '—'
                    : fmt.format(_restriction.codUpdatedAt!),
              ),
              if (_restriction.codRestrictionNotes.isNotEmpty)
                _kv('Admin Notes', _restriction.codRestrictionNotes),
              if (_history.isNotEmpty) ...[
                const Divider(height: 28),
                Text(
                  'Restriction history',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._history.take(8).map((h) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${h.createdAt != null ? fmt.format(h.createdAt!) : '—'} · '
                      '${h.adminName} · ${h.action}'
                      '${h.reason.isNotEmpty ? ' — ${h.reason}' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(k, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final CodRestrictionBadge badge;

  @override
  Widget build(BuildContext context) {
    final color = switch (badge) {
      CodRestrictionBadge.enabled => const Color(0xFF059669),
      CodRestrictionBadge.disabled => const Color(0xFFDC2626),
      CodRestrictionBadge.temporary => const Color(0xFFD97706),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '${badge.emoji} ${badge.label}',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: color,
        ),
      ),
    );
  }
}
