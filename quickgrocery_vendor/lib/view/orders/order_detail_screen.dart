import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../services/order_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import 'invoice_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final VendorModel vendor;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.vendor,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _currentOrder;
  final OrderService _orderService = OrderService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _confirmOrder() async {
    // Show confirmation dialog
    final shouldConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Are you sure you want to confirm this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (shouldConfirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update order status to "Order Confirm"
      await _orderService.updateOrderStatus(_currentOrder.id, 'Order Confirm');
      
      // Update confirmed time
      final now = DateTime.now().toIso8601String();
      await _orderService.updateOrderConfirmedTime(_currentOrder.id, now);

      // Update local state
      setState(() {
        _currentOrder = OrderModel(
          id: _currentOrder.id,
          products: _currentOrder.products,
          createdDate: _currentOrder.createdDate,
          customerName: _currentOrder.customerName,
          phone: _currentOrder.phone,
          address: _currentOrder.address,
          isPaid: _currentOrder.isPaid,
          orderStatus: 'Order Confirm',
          deliveryBoyId: _currentOrder.deliveryBoyId,
          isDelivered: _currentOrder.isDelivered,
          isCancelled: _currentOrder.isCancelled,
          deliveryType: _currentOrder.deliveryType,
          isRated: _currentOrder.isRated,
          rating: _currentOrder.rating,
          confimedTime: now,
          driverGoShopTime: _currentOrder.driverGoShopTime,
          orderPickedTime: _currentOrder.orderPickedTime,
          onTheWayTime: _currentOrder.onTheWayTime,
          orderDeliveredTime: _currentOrder.orderDeliveredTime,
          deliveryCharge: _currentOrder.deliveryCharge,
          uuid: _currentOrder.uuid,
          currentLocation: _currentOrder.currentLocation,
          lat: _currentOrder.lat,
          lng: _currentOrder.lng,
        );
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
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

  @override
  Widget build(BuildContext context) {
    final vendorProducts = _currentOrder.products.where((p) => p.vendorId == widget.vendor.id).toList();
    final vendorRevenue = _orderService.getVendorRevenueFromOrder(_currentOrder, widget.vendor.id);
    final canConfirm = _currentOrder.orderStatus.toLowerCase() == 'waiting';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Order #${_currentOrder.id.substring(0, 8)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentOrder.orderStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_currentOrder.orderStatus),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _currentOrder.orderStatus,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(_currentOrder.orderStatus),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h15,
                    Row(
                      children: [
                        Icon(
                          _currentOrder.isPaid ? Icons.payment : Icons.payment_outlined,
                          size: 20,
                          color: _currentOrder.isPaid ? Colors.green : Colors.orange,
                        ),
                        AppSpacing.w10,
                        Text(
                          _currentOrder.isPaid ? 'Payment Received' : 'Payment Pending',
                          style: TextStyle(
                            fontSize: 14,
                            color: _currentOrder.isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (canConfirm) ...[
                      AppSpacing.h20,
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _confirmOrder,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isLoading ? 'Confirming...' : 'Confirm Order',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AppSpacing.h20,

            // Customer Information
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            AppSpacing.h15,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: _currentOrder.customerName,
                    ),
                    AppSpacing.h15,
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _currentOrder.phone,
                    ),
                    AppSpacing.h15,
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _currentOrder.address,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.h20,

            // Order Items
            Text(
              'Order Items (${vendorProducts.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            AppSpacing.h15,
            Card(
              child: Column(
                children: vendorProducts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  final isLast = index == vendorProducts.length - 1;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.image.isNotEmpty
                                  ? Image.network(
                                      product.image,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                            ),
                            AppSpacing.w15,

                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  AppSpacing.h5,
                                  Text(
                                    product.category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  AppSpacing.h10,
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Qty: ${product.itemCount} ${product.unit}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '₹${(product.price * product.itemCount).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isLast) ...[
                          AppSpacing.h15,
                          Divider(color: Colors.grey[300]),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            AppSpacing.h20,

            // Order Summary
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            AppSpacing.h15,
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      value: '₹${_currentOrder.getSubtotal().toStringAsFixed(2)}',
                    ),
                    AppSpacing.h10,
                    _SummaryRow(
                      label: 'Delivery Charge',
                      value: '₹${_currentOrder.deliveryCharge.toStringAsFixed(2)}',
                    ),
                    AppSpacing.h15,
                    Divider(color: Colors.grey[300]),
                    AppSpacing.h15,
                    _SummaryRow(
                      label: 'Total Order Amount',
                      value: '₹${_currentOrder.getTotalAmount().toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    AppSpacing.h15,
                    Divider(color: Colors.grey[300]),
                    AppSpacing.h15,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Revenue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '₹${vendorRevenue.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.h20,

            // Order Timeline
            if (_currentOrder.confimedTime.isNotEmpty ||
                _currentOrder.driverGoShopTime.isNotEmpty ||
                _currentOrder.orderPickedTime.isNotEmpty ||
                _currentOrder.onTheWayTime.isNotEmpty ||
                _currentOrder.orderDeliveredTime.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  AppSpacing.h15,
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_currentOrder.confimedTime.isNotEmpty)
                            _TimelineItem(
                              icon: Icons.check_circle_outline,
                              label: 'Confirmed',
                              time: _formatDate(_currentOrder.confimedTime),
                              isCompleted: true,
                            ),
                          if (_currentOrder.driverGoShopTime.isNotEmpty) ...[
                            AppSpacing.h15,
                            _TimelineItem(
                              icon: Icons.store,
                              label: 'Driver at Shop',
                              time: _formatDate(_currentOrder.driverGoShopTime),
                              isCompleted: true,
                            ),
                          ],
                          if (_currentOrder.orderPickedTime.isNotEmpty) ...[
                            AppSpacing.h15,
                            _TimelineItem(
                              icon: Icons.shopping_bag,
                              label: 'Order Picked',
                              time: _formatDate(_currentOrder.orderPickedTime),
                              isCompleted: true,
                            ),
                          ],
                          if (_currentOrder.onTheWayTime.isNotEmpty) ...[
                            AppSpacing.h15,
                            _TimelineItem(
                              icon: Icons.local_shipping,
                              label: 'On The Way',
                              time: _formatDate(_currentOrder.onTheWayTime),
                              isCompleted: true,
                            ),
                          ],
                          if (_currentOrder.orderDeliveredTime.isNotEmpty) ...[
                            AppSpacing.h15,
                            _TimelineItem(
                              icon: Icons.check_circle,
                              label: 'Delivered',
                              time: _formatDate(_currentOrder.orderDeliveredTime),
                              isCompleted: true,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            AppSpacing.h20,

            // Generate Invoice Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InvoiceScreen(
                        order: _currentOrder,
                        vendor: widget.vendor,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text(
                  'Generate Invoice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            AppSpacing.h20,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
                        AppSpacing.w15,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              AppSpacing.h5,
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColor.primary : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isCompleted;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isCompleted ? Colors.green : Colors.grey[400],
        ),
                        AppSpacing.w15,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Colors.grey[800] : Colors.grey[400],
                ),
              ),
                      const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

