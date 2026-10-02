import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_segment.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:quick_grocery_admin/view/customers/widgets/customer_management_table.dart';
import 'package:quick_grocery_admin/view/customers/widgets/customer_summary_cards.dart';

/// Simple real-time customer management list.
class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, required this.segment});

  final CustomerSegment segment;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerAdminService>().setSegment(widget.segment);
    });
  }

  @override
  void didUpdateWidget(covariant CustomerListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segment != widget.segment) {
      context.read<CustomerAdminService>().setSegment(widget.segment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<CustomerAdminService>();

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.segment.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${svc.sortedFiltered.length} shown · ${svc.summary.totalCustomers} total · ${svc.summary.onlineNow} online',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                const CustomerSummaryCards(),
                const SizedBox(height: 16),
                TextField(
                  controller: svc.searchController,
                  onChanged: svc.setSearch,
                  decoration: InputDecoration(
                    hintText: 'Search name, phone, or email…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    suffixIcon: svc.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              svc.searchController.clear();
                              svc.setSearch('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Platform',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: svc.platformFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All platforms'),
                              ),
                              DropdownMenuItem(
                                value: 'android',
                                child: Text('Android'),
                              ),
                              DropdownMenuItem(
                                value: 'ios',
                                child: Text('iOS'),
                              ),
                              DropdownMenuItem(
                                value: 'web',
                                child: Text('Web'),
                              ),
                              DropdownMenuItem(
                                value: 'unknown',
                                child: Text('Unknown'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) svc.setPlatformFilter(v);
                            },
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'App version',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: svc.availableAppVersions
                                        .contains(svc.appVersionFilter) ||
                                    svc.appVersionFilter == 'all' ||
                                    svc.appVersionFilter == 'unknown'
                                ? svc.appVersionFilter
                                : 'all',
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All versions'),
                              ),
                              const DropdownMenuItem(
                                value: 'unknown',
                                child: Text('Unknown'),
                              ),
                              ...svc.availableAppVersions.map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) svc.setAppVersionFilter(v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CustomerManagementTable(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
