import 'package:flutter/material.dart';
import '../../core/vendor_order_notification_controller.dart';
import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../services/order_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import 'order_detail_screen.dart';
import 'invoice_screen.dart';
import 'widgets/assign_rider_sheet.dart';

class OrdersScreen extends StatefulWidget {
  final VendorModel vendor;
  final VendorOrderNotificationController notifications;
  final VoidCallback? onOpenNotificationCenter;
  final Widget? bottomNavigationBar;

  const OrdersScreen({
    super.key,
    required this.vendor,
    required this.notifications,
    this.onOpenNotificationCenter,
    this.bottomNavigationBar,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  String _selectedFilter = 'All';
  Stream<List<OrderModel>>? _ordersStream;

  final List<String> _filterOptions = [
    'All',
    'waiting',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _bindOrdersStream();
  }

  void _bindOrdersStream() {
    _ordersStream = _orderService.watchVendorOrders(
      widget.vendor.id,
      statusFilter: _selectedFilter,
    );
  }

  String _filterLabel(String filter) {
    if (filter == 'All') return 'All';
    return filter[0].toUpperCase() + filter.substring(1);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'order confirm':
        return Colors.blue;
      case 'going to shop':
        return Colors.purple;
      case 'order picked':
        return Colors.indigo;
      case 'on the way':
        return Colors.indigo;
      case 'order delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Icons.pending;
      case 'order confirm':
        return Icons.check_circle_outline;
      case 'going to shop':
        return Icons.store;
      case 'order picked':
        return Icons.shopping_bag;
      case 'on the way':
        return Icons.local_shipping;
      case 'order delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.notifications,
            builder: (context, _) {
              return IconButton(
                tooltip: 'Notifications',
                onPressed: widget.onOpenNotificationCenter,
                icon: Badge(
                  isLabelVisible: widget.notifications.badgeCount > 0,
                  label: Text('${widget.notifications.badgeCount}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _bindOrdersStream();
                        });
                      },
                      selectedColor: AppColor.primary,
                      checkmarkColor: Colors.black,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        AppSpacing.h20,
                        Text(
                          'Error loading orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        AppSpacing.h10,
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        AppSpacing.h20,
                        Text(
                          'No orders found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppSpacing.h10,
                        Text(
                          _selectedFilter == 'All'
                              ? 'You don\'t have any orders yet'
                              : 'No ${_filterLabel(_selectedFilter)} orders',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isNew = _isPendingNew(order);
                    return _OrderCard(
                      order: order,
                      vendorId: widget.vendor.id,
                      vendor: widget.vendor,
                      orderService: _orderService,
                      statusColor: _getStatusColor(order.orderStatus),
                      statusIcon: _getStatusIcon(order.orderStatus),
                      highlight: isNew,
                      onAssignRider: order.deliveryBoyId.isEmpty &&
                              !order.isDelivered &&
                              !order.isCancelled
                          ? () => AssignRiderSheet.show(
                                context,
                                order: order,
                                orderService: _orderService,
                              )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailScreen(
                              order: order,
                              vendor: widget.vendor,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  bool _isPendingNew(OrderModel order) {
    if (order.isDelivered || order.isCancelled) return false;
    final s = order.orderStatus.toLowerCase();
    return s.contains('waiting') ||
        s.contains('pending') ||
        s.contains('confirm') && order.confimedTime.isEmpty;
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final String vendorId;
  final VendorModel vendor;
  final OrderService orderService;
  final Color statusColor;
  final IconData statusIcon;
  final bool highlight;
  final VoidCallback? onAssignRider;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.vendorId,
    required this.vendor,
    required this.orderService,
    required this.statusColor,
    required this.statusIcon,
    this.highlight = false,
    this.onAssignRider,
    required this.onTap,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate vendor's revenue from this order
    final vendorRevenue = orderService.getVendorRevenueFromOrder(order, vendorId);
    final vendorProducts = order.products.where((p) => p.vendorId == vendorId).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: highlight ? 4 : 2,
      color: highlight ? Colors.orange.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight
            ? BorderSide(color: Colors.orange.shade400, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        AppSpacing.h5,
                        Text(
                          _formatDate(order.createdDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        AppSpacing.w5,
                        Text(
                          order.orderStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.h15,

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  AppSpacing.w10,
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
                      AppSpacing.h10,
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  AppSpacing.w10,
                  Text(
                    order.phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              AppSpacing.h15,

              // Products Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vendorProducts.length} item${vendorProducts.length > 1 ? 's' : ''} from your store',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                      AppSpacing.h10,
                    ...vendorProducts.take(2).map((product) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                '• ${product.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              AppSpacing.w10,
                              Text(
                                'x${product.itemCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (vendorProducts.length > 2)
                      Text(
                        '+ ${vendorProducts.length - 2} more',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.h15,

              // Revenue and Payment Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Revenue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      AppSpacing.h5,
                      Text(
                        '₹${vendorRevenue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: order.isPaid
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          order.isPaid ? Icons.payment : Icons.payment_outlined,
                          size: 16,
                          color: order.isPaid ? Colors.green : Colors.orange,
                        ),
                        AppSpacing.w5,
                        Text(
                          order.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: order.isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.h15,
              if (onAssignRider != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: onAssignRider,
                    icon: const Icon(Icons.delivery_dining, size: 18),
                    label: const Text('Assign Driver'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                AppSpacing.h10,
              ],
              if (order.deliveryBoyId.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.two_wheeler, size: 16, color: Colors.grey[700]),
                      AppSpacing.w10,
                      Expanded(
                        child: Text(
                          'Rider assigned',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Generate Invoice Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InvoiceScreen(
                          order: order,
                          vendor: vendor,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text(
                    'Generate Invoice',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: BorderSide(color: AppColor.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

