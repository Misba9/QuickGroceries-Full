import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/view/customers/widgets/customer_management_table.dart';

@Deprecated('Use CustomerManagementTable.')
class CustomerDataTable extends StatelessWidget {
  const CustomerDataTable({super.key});

  @override
  Widget build(BuildContext context) => const CustomerManagementTable();
}

/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/core/utils/duration_format.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_profile_screen.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/widgets/customer_action_menu.dart';

class CustomerDataTable extends StatelessWidget {
  const CustomerDataTable({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<CustomerAdminService>();

    if (svc.errorMessage != null && svc.enriched.isEmpty) {
      return _ErrorState(message: svc.errorMessage!);
    }
    if (svc.isLoading && svc.enriched.isEmpty) {
      return const _TableSkeleton();
    }
    if (!svc.isLoading && svc.filtered.isEmpty) {
      return const _EmptyState();
    }

    final rows = svc.paged;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, c) {
        final dt = DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('User name', style: _h)),
            DataColumn(label: Text('Phone', style: _h)),
            DataColumn(label: Text('Email', style: _h)),
            DataColumn(label: Text('Orders', style: _h)),
            DataColumn(label: Text('Total spend', style: _h)),
            DataColumn(label: Text('Last active', style: _h)),
            DataColumn(label: Text('Status', style: _h)),
            DataColumn(label: Text('Actions', style: _h)),
          ],
          rows: rows.map((e) {
            final c = e.customer;
            final last = c.lastActiveTs ?? e.stats.lastOrderAt;
            return DataRow(
              onSelectChanged: (_) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerProfileScreen(enriched: e),
                  ),
                );
              },
              cells: [
                DataCell(
                  Row(
                    children: [
                      if (c.isOnline)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          c.name.isEmpty ? '—' : c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(c.phoneNumber.isEmpty ? '—' : c.phoneNumber)),
                DataCell(
                  Text(
                    c.email.isEmpty ? '—' : c.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DataCell(Text('${e.stats.totalOrders}')),
                DataCell(Text(currency.format(e.stats.totalSpend))),
                DataCell(Text(_lastActive(last, c.isOnline))),
                DataCell(_statusBadge(c)),
                DataCell(CustomerRowActions(enriched: e)),
              ],
            );
          }).toList(),
        );

        return Column(
          children: [
            adminScrollableDataTable(viewportWidth: c.maxWidth, dataTable: dt),
            if (svc.hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  onPressed: svc.loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    'Load more (${svc.filtered.length - rows.length} remaining)',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _lastActive(DateTime? dt, bool online) {
    if (online) return 'Online';
    if (dt == null) return '—';
    return DurationFormat.formatElapsed(dt);
  }

  static Widget _statusBadge(CustomerModel c) {
    final blocked = c.isBlocked || c.status == CustomerAccountStatus.blocked;
    final label = blocked ? 'Blocked' : 'Active';
    final color = blocked ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  static const _h = TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        8,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No customers match your filters', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
*/
