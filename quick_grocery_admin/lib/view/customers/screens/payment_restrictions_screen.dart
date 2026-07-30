import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/cod_payment_restriction.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/customers/services/cod_restriction_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/widgets/cod_restriction_editor_dialog.dart';

/// **Users → Payment Restrictions** — browse and manage COD-restricted customers.
class PaymentRestrictionsScreen extends StatefulWidget {
  const PaymentRestrictionsScreen({super.key});

  @override
  State<PaymentRestrictionsScreen> createState() =>
      _PaymentRestrictionsScreenState();
}

class _PaymentRestrictionsScreenState extends State<PaymentRestrictionsScreen> {
  final _svc = CodRestrictionAdminService();
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<CodRestrictedCustomerRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _svc.listRestricted();
      if (!mounted) return;
      setState(() {
        _rows = rows;
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

  List<CodRestrictedCustomerRow> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.phone.contains(q) ||
          r.email.toLowerCase().contains(q) ||
          r.userId.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _manage(CodRestrictedCustomerRow row) async {
    final ok = await showCodRestrictionEditor(
      context: context,
      userId: row.userId,
      userName: row.name,
      current: row.restriction,
    );
    if (ok == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y');
    return ColoredBox(
      color: const Color(0xFFFFFAF0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = adminResponsivePadding(constraints.maxWidth);
          return Column(
            children: [
              AppSpacing.h20,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pad),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Users → Payment Restrictions',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Payment Restrictions',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Disable Cash on Delivery for users who abused COD '
                            '(fake orders, repeated cancellations, fraud). '
                            'Restricted users can still place prepaid orders.',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: 'Search name, phone, email, UID…',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: _loading ? null : _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_error != null)
                            Material(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red.shade800),
                                ),
                              ),
                            )
                          else if (_filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                'No COD-restricted users right now.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          else
                            Material(
                              color: Colors.white,
                              elevation: 2,
                              borderRadius: BorderRadius.circular(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: DataTable(
                                  headingRowColor: WidgetStatePropertyAll(
                                    Colors.grey.shade50,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('User')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Reason')),
                                    DataColumn(label: Text('Ends')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: [
                                    for (final r in _filtered)
                                      DataRow(
                                        cells: [
                                          DataCell(
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  r.name.isEmpty
                                                      ? r.userId
                                                      : r.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  [
                                                    if (r.phone.isNotEmpty)
                                                      r.phone,
                                                    if (r.email.isNotEmpty)
                                                      r.email,
                                                  ].join(' · '),
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${r.restriction.badge.emoji} ${r.restriction.badge.label}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: switch (
                                                    r.restriction.badge) {
                                                  CodRestrictionBadge.enabled =>
                                                    const Color(0xFF059669),
                                                  CodRestrictionBadge
                                                        .disabled =>
                                                    const Color(0xFFDC2626),
                                                  CodRestrictionBadge
                                                        .temporary =>
                                                    const Color(0xFFD97706),
                                                },
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 180,
                                              child: Text(
                                                r.restriction
                                                        .codRestrictionReason
                                                        .isEmpty
                                                    ? '—'
                                                    : r.restriction
                                                        .codRestrictionReason,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              r.restriction.codRestrictionEnd ==
                                                      null
                                                  ? '—'
                                                  : fmt.format(
                                                      r.restriction
                                                          .codRestrictionEnd!,
                                                    ),
                                            ),
                                          ),
                                          DataCell(
                                            TextButton(
                                              onPressed: () => _manage(r),
                                              child: const Text('Manage'),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            'Tip: open any customer profile (User Management) to manage COD '
                            'and view full restriction history for that user.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
