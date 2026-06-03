import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/utils/duration_format.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_sort.dart';
import 'package:quick_grocery_admin/view/customers/screens/customer_profile_screen.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/widgets/customer_action_menu.dart';
import 'package:quick_grocery_admin/core/widgets/admin_text_selection.dart';

class CustomerManagementTable extends StatelessWidget {
  const CustomerManagementTable({super.key});

  @override
  Widget build(BuildContext context) {
    final error = context.select<CustomerAdminService, String?>(
      (s) => s.errorMessage,
    );
    final isLoading = context.select<CustomerAdminService, bool>(
      (s) => s.isLoading,
    );
    final hasData = context.select<CustomerAdminService, bool>(
      (s) => s.enriched.isNotEmpty,
    );
    final isEmpty = context.select<CustomerAdminService, bool>(
      (s) => !s.isLoading && s.sortedFiltered.isEmpty,
    );

    if (error != null && !hasData) {
      return Center(child: _ErrorState(message: error));
    }
    if (isLoading && !hasData) {
      return const _TableSkeleton();
    }
    if (isEmpty) {
      return const _EmptyState();
    }

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _ScrollableCustomerTable()),
        _LoadMoreBar(),
      ],
    );
  }
}

class _ScrollableCustomerTable extends StatelessWidget {
  const _ScrollableCustomerTable();

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<CustomerAdminService>();
    final rows = svc.paged;
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTableWidth = math.max(constraints.maxWidth, 980.0);
        final table = DataTable(
          sortColumnIndex: _sortColumnIndex(svc.sortField),
          sortAscending: svc.sortAscending,
          showCheckboxColumn: false,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          headingRowHeight: 48,
          dataRowMinHeight: 52,
          dataRowMaxHeight: 56,
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: [
            _sortColumn(svc, CustomerSortField.name),
            const DataColumn(label: Text('Phone', style: _h)),
            const DataColumn(label: Text('Email', style: _h)),
            _sortColumn(svc, CustomerSortField.orders),
            _sortColumn(svc, CustomerSortField.spend),
            _sortColumn(svc, CustomerSortField.lastActive),
            const DataColumn(label: Text('Status', style: _h)),
            const DataColumn(label: Text('Actions', style: _h)),
          ],
          rows: rows
              .map((e) => _buildRow(context, e, currency))
              .toList(growable: false),
        );

        return Scrollbar(
          child: SingleChildScrollView(
            primary: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: table,
              ),
            ),
          ),
        );
      },
    );
  }

  static DataColumn _sortColumn(
    CustomerAdminService svc,
    CustomerSortField field,
  ) {
    final isActive = svc.sortField == field;
    final hint = svc.sortHintFor(field);

    return DataColumn(
      onSort: (_, __) => svc.toggleSort(field),
      label: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label, style: _h),
          if (isActive)
            Text(
              hint,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
        ],
      ),
    );
  }

  static DataRow _buildRow(
    BuildContext context,
    CustomerEnriched e,
    NumberFormat currency,
  ) {
    final c = e.customer;
    final last = c.lastActiveTs ?? e.stats.lastOrderAt;

    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => _openProfile(context, e),
            child: Row(
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
                  child: AdminSelectableText(
                    c.name.isEmpty ? '—' : c.name,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          AdminSelectableText(
            c.phoneNumber.isEmpty ? '—' : c.phoneNumber,
          ),
        ),
        DataCell(
          AdminSelectableText(
            c.email.isEmpty ? '—' : c.email,
            maxLines: 1,
          ),
        ),
        DataCell(Text('${e.stats.totalOrders}')),
        DataCell(Text(currency.format(e.stats.totalSpend))),
        DataCell(Text(_lastActive(last, c.isOnline))),
        DataCell(_statusBadge(c)),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: CustomerRowActions(enriched: e),
          ),
        ),
      ],
    );
  }

  static void _openProfile(BuildContext context, CustomerEnriched e) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerProfileScreen(enriched: e)),
    );
  }

  static int _sortColumnIndex(CustomerSortField field) {
    switch (field) {
      case CustomerSortField.name:
        return 0;
      case CustomerSortField.orders:
        return 3;
      case CustomerSortField.spend:
        return 4;
      case CustomerSortField.lastActive:
        return 5;
    }
  }

  static String _lastActive(DateTime? dt, bool online) {
    if (online) return 'Online now';
    if (dt == null) return '—';
    return DurationFormat.formatElapsed(dt);
  }

  static Widget _statusBadge(CustomerModel c) {
    final blocked = c.isBlocked || c.status == CustomerAccountStatus.blocked;
    final label = blocked ? 'Blocked' : 'Active';
    final color = blocked ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static const _h = TextStyle(fontWeight: FontWeight.w700, fontSize: 12);
}

class _LoadMoreBar extends StatelessWidget {
  const _LoadMoreBar();

  @override
  Widget build(BuildContext context) {
    final hasMore = context.select<CustomerAdminService, bool>(
      (s) => s.hasMore,
    );
    if (!hasMore) return const SizedBox.shrink();

    final remaining = context.select<CustomerAdminService, int>(
      (s) => s.sortedFiltered.length - s.paged.length,
    );

    return Material(
      color: const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: context.read<CustomerAdminService>().loadMore,
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text('Load more ($remaining remaining)'),
          ),
        ),
      ),
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'No customers match your filters',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
