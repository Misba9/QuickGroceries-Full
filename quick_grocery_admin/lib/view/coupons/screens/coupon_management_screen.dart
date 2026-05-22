import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/coupons/models/admin_coupon_model.dart';
import 'package:quick_grocery_admin/view/coupons/models/coupon_type.dart';
import 'package:quick_grocery_admin/view/coupons/services/coupon_admin_service.dart';
import 'package:quick_grocery_admin/view/coupons/widgets/coupon_analytics_cards.dart';
import 'package:quick_grocery_admin/view/coupons/widgets/coupon_form_sheet.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  final _service = CouponAdminService();
  final _search = TextEditingController();
  CouponListFilter _filter = CouponListFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm({AdminCouponModel? existing}) async {
    final model = await CouponFormSheet.show(
      context,
      existing: existing,
      service: _service,
    );
    if (model == null || !mounted) return;
    try {
      if (existing == null) {
        await _service.createCoupon(model);
      } else {
        await _service.updateCoupon(model);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing == null ? 'Coupon created' : 'Coupon updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDelete(AdminCouponModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('Remove ${c.code}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _service.deleteCoupon(c.id);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = adminResponsivePadding(w);
        final narrow = adminIsMobileWidth(w);

        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: StreamBuilder<List<AdminCouponModel>>(
            stream: _service.watchCoupons(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const AdminBoundedCenter(
                  child: CircularProgressIndicator(),
                );
              }
              final all = snap.data!;
              final summary = _service.summarize(all);
              final filtered = _service.filterCoupons(
                all,
                search: _search.text,
                filter: _filter,
              );

              return Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Coupon Management',
                            style: TextStyle(
                              fontSize: adminResponsiveFontSize(
                                w,
                                mobile: 20,
                                tablet: 22,
                                desktop: 24,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add),
                          label: Text(narrow ? 'New' : 'Create coupon'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h20,
                    CouponAnalyticsCards(summary: summary),
                    AppSpacing.h20,
                    WrapperWidget(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (narrow) ...[
                            TextField(
                              controller: _search,
                              decoration: InputDecoration(
                                hintText: 'Search coupons…',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            AppSpacing.h10,
                            _FilterChips(
                              selected: _filter,
                              onSelected: (f) => setState(() => _filter = f),
                            ),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _search,
                                    decoration: InputDecoration(
                                      hintText: 'Search by code or description…',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                AppSpacing.w10,
                                Expanded(
                                  flex: 3,
                                  child: _FilterChips(
                                    selected: _filter,
                                    onSelected: (f) => setState(() => _filter = f),
                                  ),
                                ),
                              ],
                            ),
                          AppSpacing.h15,
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('No coupons match filters')),
                            )
                          else if (narrow)
                            ...filtered.map((c) => _CouponCard(
                                  coupon: c,
                                  onEdit: () => _openForm(existing: c),
                                  onDelete: () => _confirmDelete(c),
                                ))
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 16,
                                headingRowHeight: 48,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 72,
                                columns: const [
                                  DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Min order', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Usage', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((c) {
                                  return DataRow(cells: [
                                    DataCell(Text(c.code, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(c.couponType.label)),
                                    DataCell(Text(_discountLabel(c))),
                                    DataCell(Text('₹${c.minimumOrderAmount}')),
                                    DataCell(Text('${c.usedCount}${c.usageLimit > 0 ? '/${c.usageLimit}' : ''}')),
                                    DataCell(_StatusPill(coupon: c)),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _openForm(existing: c),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDelete(c),
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _discountLabel(AdminCouponModel c) {
    if (c.freeDelivery && c.discountPercent <= 0 && c.flatAmount <= 0) {
      return 'Free delivery';
    }
    if (c.flatAmount > 0) return '₹${c.flatAmount} off';
    if (c.discountPercent > 0) return '${c.discountPercent}%';
    return '—';
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final CouponListFilter selected;
  final ValueChanged<CouponListFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CouponListFilter.values.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.label),
              selected: selected == f,
              onSelected: (_) => onSelected(f),
              selectedColor: AppColor.primary.withValues(alpha: 0.35),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.coupon});

  final AdminCouponModel coupon;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (coupon.statusLabel) {
      case 'Active':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case 'Expired':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      case 'Scheduled':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(coupon.statusLabel, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminCouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${coupon.couponType.label} · Used ${coupon.usedCount} · Failed ${coupon.analyticsFailedAttempts}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusPill(coupon: coupon),
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
