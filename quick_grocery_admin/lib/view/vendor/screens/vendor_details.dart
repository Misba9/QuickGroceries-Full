import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_status_utils.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_security_sheet.dart';
import 'package:quick_grocery_admin/view/vendor/screens/vendor_list_screen.dart';
import 'package:quick_grocery_admin/view/vendor/models/vendor_profile_stats.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';
import 'package:quick_grocery_admin/view/vendor/utils/vendor_order_utils.dart';
import 'package:quick_grocery_admin/view/vendor/widgets/vendor_auth_recovery_sheet.dart';

class VendorDetailsScreen extends StatefulWidget {
  const VendorDetailsScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _ordersPage = 0;
  static const _ordersPageSize = 25;
  VendorService? _vendorService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _vendorService = context.read<VendorService>();
      _vendorService!.watchVendorProfile(widget.vendorId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vendorService?.stopWatchingVendorProfile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: Column(
        children: [
          const PrimaryAppBar(isBackButton: true),
          Expanded(
            child: Consumer<VendorService>(
              builder: (context, svc, _) {
                if (svc.profileLoading && svc.vendor == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (svc.profileError != null && svc.vendor == null) {
                  return _ErrorState(
                    message: svc.profileError!,
                    onRetry: () =>
                        svc.watchVendorProfile(widget.vendorId),
                  );
                }
                final v = svc.vendor;
                if (v == null) {
                  return const Center(child: Text('Vendor not found'));
                }
                final stats = svc.profileStats;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderRow(vendor: v, stats: stats),
                      AppSpacing.h10,
                      _AnalyticsGrid(stats: stats),
                      AppSpacing.h10,
                      _ActionBar(vendor: v, vendorId: widget.vendorId),
                      AppSpacing.h10,
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColor.primary,
                        tabs: [
                          Tab(text: 'Overview (${stats.activeProducts} products)'),
                          Tab(text: 'Products (${stats.totalProducts})'),
                          Tab(text: 'Orders (${stats.totalOrders})'),
                        ],
                      ),
                      AppSpacing.h5,
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _OverviewTab(vendor: v, stats: stats),
                            _ProductsTab(
                              products: svc.products,
                              loading: svc.products == null,
                            ),
                            _OrdersTab(
                              orders: svc.orders,
                              loading: svc.profileOrdersLoading &&
                                  svc.orders == null,
                              page: _ordersPage,
                              pageSize: _ordersPageSize,
                              onPageChanged: (p) =>
                                  setState(() => _ordersPage = p),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.vendor, required this.stats});

  final VendorModel vendor;
  final VendorProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: vendor.shopImage.isNotEmpty
              ? Image.network(
                  vendor.shopImage,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _shopPlaceholder(),
                )
              : _shopPlaceholder(),
        ),
        AppSpacing.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset('assets/icons/userplus.svg', width: 20),
                  AppSpacing.w5,
                  Expanded(
                    child: Text(
                      vendor.shopName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _LiveBadge(),
                ],
              ),
              Text(
                vendor.ownerName,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              AppSpacing.h5,
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(
                    label: vendor.displayStatus.toUpperCase(),
                    color: _statusColor(vendor),
                  ),
                  _StatusChip(
                    label: vendor.needsFirebaseAuthSync
                        ? 'Auth: Not synced'
                        : 'Auth: Synced',
                    color: vendor.needsFirebaseAuthSync
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _StatusChip(
                    label: vendor.isVendorActive ? 'Online' : 'Offline',
                    color: vendor.isVendorActive ? Colors.teal : Colors.grey,
                  ),
                ],
              ),
              AppSpacing.h5,
              Text(
                '${vendor.email} · ${vendor.phone}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shopPlaceholder() => Container(
        width: 88,
        height: 88,
        color: Colors.grey.shade300,
        child: const Icon(Icons.storefront_outlined, size: 36),
      );

  Color _statusColor(VendorModel v) {
    switch (v.displayStatus) {
      case 'suspended':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'active':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  const _AnalyticsGrid({required this.stats});

  final VendorProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard('Active Products', '${stats.activeProducts}', Icons.inventory_2_outlined),
      _StatCard('Total Orders', '${stats.totalOrders}', Icons.receipt_long_outlined),
      _StatCard('Revenue', '₹${stats.revenue.toStringAsFixed(0)}', Icons.currency_rupee),
      _StatCard('Pending', '${stats.pendingOrders}', Icons.pending_actions_outlined),
      _StatCard('Completed', '${stats.completedOrders}', Icons.check_circle_outline),
      _StatCard(
        'Avg Rating',
        stats.avgRating > 0 ? stats.avgRating.toStringAsFixed(1) : '—',
        Icons.star_outline,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final crossCount = c.maxWidth > 900 ? 6 : (c.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: cards,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColor.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColor.primary),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.vendor, required this.vendorId});

  final VendorModel vendor;
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<VendorService>();
    final stats = svc.profileStats;
    final canDelete =
        stats.totalProducts == 0 && stats.activeOrders == 0 && !svc.isLoading;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => PartnerSecuritySheet.show(
            context,
            role: 'vendor',
            partnerId: vendor.id,
            email: vendor.email,
            isActive: vendor.isVendorActive,
          ),
          icon: const Icon(Icons.security, size: 18),
          label: const Text('Account security'),
        ),
        OutlinedButton.icon(
          onPressed: () => VendorAuthRecoverySheet.show(context, vendor),
          icon: const Icon(Icons.healing_outlined, size: 18),
          label: const Text('Auth recovery'),
        ),
        FilledButton.icon(
          onPressed: svc.isLoading
              ? null
              : () => _toggleSuspension(context, svc),
          style: FilledButton.styleFrom(
            backgroundColor: vendor.isSuspended ? Colors.green : Colors.red,
          ),
          icon: Icon(
            vendor.isSuspended ? Icons.check_circle_outline : Icons.block,
            size: 18,
          ),
          label: Text(vendor.isSuspended ? 'Activate' : 'Suspend'),
        ),
        OutlinedButton.icon(
          onPressed: !canDelete || svc.isLoading
              ? null
              : () => _confirmDelete(context, svc),
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
          label: const Text('Delete vendor', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Future<void> _toggleSuspension(BuildContext context, VendorService svc) async {
    final suspend = !vendor.isSuspended;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspend ? 'Suspend vendor?' : 'Activate vendor?'),
        content: Text(
          suspend
              ? '${vendor.shopName} will be blocked from logging in until reactivated.'
              : '${vendor.shopName} will be able to log in again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(suspend ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      if (suspend) {
        await svc.suspendVendor(vendorId);
      } else {
        await svc.activateVendor(vendorId);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            suspend ? 'Vendor suspended.' : 'Vendor activated.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, VendorService svc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vendor?'),
        content: Text(
          'Permanently delete ${vendor.shopName}? This removes the Firestore profile '
          'and disables Firebase Auth. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await svc.deleteVendor(context, vendorId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.vendor, required this.stats});

  final VendorModel vendor;
  final VendorProfileStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop information', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.h5,
          _InfoTile(Icons.location_on_outlined, 'Address', vendor.shopAddress),
          _InfoTile(Icons.email_outlined, 'Email', vendor.email),
          _InfoTile(Icons.phone_outlined, 'Phone', vendor.phone),
          AppSpacing.h15,
          Text('Order breakdown', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.h5,
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _BreakdownChip('Total', stats.totalOrders, Colors.blue),
              _BreakdownChip('Pending', stats.pendingOrders, Colors.orange),
              _BreakdownChip('Completed', stats.completedOrders, Colors.green),
              _BreakdownChip('Cancelled', stats.cancelledOrders, Colors.red),
            ],
          ),
          AppSpacing.h15,
          Text('Health', style: Theme.of(context).textTheme.titleMedium),
          AppSpacing.h5,
          _InfoTile(
            Icons.health_and_safety_outlined,
            'Vendor health',
            stats.activeOrders > 0
                ? '${stats.activeOrders} active order(s) in progress'
                : 'No active orders — safe to manage profile',
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColor.primary, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text('$count', style: TextStyle(color: color, fontSize: 12)),
      ),
      label: Text(label),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products, required this.loading});

  final List<ProductModel>? products;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final list = products ?? [];
    if (list.isEmpty) {
      return const _EmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No products for this vendor yet.',
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8),
          child: adminScrollableDataTable(
            viewportWidth: c.maxWidth,
            minTableWidth: 960,
            dataTable: DataTable(
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: List.generate(list.length, (i) {
                final p = list[i];
                return DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Row(
                    children: [
                      if (p.image.isNotEmpty)
                        CircleAvatar(backgroundImage: NetworkImage(p.image), radius: 16)
                      else
                        const CircleAvatar(radius: 16, child: Icon(Icons.image, size: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                    ],
                  )),
                  DataCell(Text('₹${p.price}')),
                  DataCell(Text(p.category)),
                  DataCell(
                    Icon(
                      p.isActive ? Icons.check_circle : Icons.cancel_outlined,
                      color: p.isActive ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                  ),
                ]);
              }),
            ),
          ),
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.orders,
    required this.loading,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  final List<OrderModel>? orders;
  final bool loading;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final all = orders ?? [];
    if (all.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No orders found for this vendor.',
      );
    }

    final totalPages = (all.length / pageSize).ceil();
    final safePage = page.clamp(0, totalPages - 1);
    final start = safePage * pageSize;
    final pageItems = all.skip(start).take(pageSize).toList();

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: adminScrollableDataTable(
                  viewportWidth: c.maxWidth,
                  minTableWidth: 1100,
                  dataTable: DataTable(
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('SL', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Delivery', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: List.generate(pageItems.length, (i) {
                      final order = pageItems[i];
                      final sl = start + i + 1;
                      final style = OrderStatusUtils.styleForOrder(order);
                      final created = VendorOrderUtils.parseCreatedDate(order.createdDate);
                      return DataRow(cells: [
                        DataCell(Text('$sl')),
                        DataCell(Text('#${order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id}')),
                        DataCell(Text(order.customerName.isEmpty ? '—' : order.customerName)),
                        DataCell(Text(
                          created != null
                              ? DateFormat('MMM d, yyyy HH:mm').format(created)
                              : '—',
                        )),
                        DataCell(_PaymentBadge(isPaid: order.isPaid)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: style.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: style.border),
                            ),
                            child: Text(style.label, style: TextStyle(color: style.foreground, fontSize: 12)),
                          ),
                        ),
                        DataCell(Text('₹${order.getTotalAmount().toStringAsFixed(0)}')),
                        DataCell(Text(VendorOrderUtils.deliveryStatusLabel(order))),
                        DataCell(_OrderActions(order: order)),
                      ]);
                    }),
                  ),
                ),
              );
            },
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: safePage > 0 ? () => onPageChanged(safePage - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${safePage + 1} of $totalPages'),
                IconButton(
                  onPressed: safePage < totalPages - 1
                      ? () => onPageChanged(safePage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.isPaid});

  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isPaid ? 'Paid' : 'Unpaid', style: const TextStyle(fontSize: 12)),
    );
  }
}

class _OrderActions extends StatelessWidget {
  const _OrderActions({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      icon: Icon(Icons.more_horiz, color: AppColor.primary),
      onSelected: (v) {
        switch (v) {
          case 'view':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(order: order),
              ),
            );
          case 'track':
            OrderContactActions.trackOrder(context, order.lat, order.lng);
          case 'invoice':
            InvoiceService.printInvoice(order: order, context: context);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'view', child: Text('View Order')),
        PopupMenuItem(value: 'track', child: Text('Track Delivery')),
        PopupMenuItem(value: 'invoice', child: Text('Open Invoice')),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          AppSpacing.h10,
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          AppSpacing.h10,
          Text(message, textAlign: TextAlign.center),
          AppSpacing.h10,
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
