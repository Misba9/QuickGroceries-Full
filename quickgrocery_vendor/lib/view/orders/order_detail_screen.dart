import 'package:flutter/material.dart';
import 'package:quick_grocery_geo/quick_grocery_geo.dart';
import '../../core/order_lifecycle.dart';
import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../services/order_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';
import '../../utils/vendor_order_display.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import 'invoice_screen.dart';
import '../../services/customer_phone_resolver.dart';

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
  String _customerPhone = '';

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _loadCustomerPhone();
  }

  Future<void> _loadCustomerPhone() async {
    final phone = await CustomerPhoneResolver.resolve(
      orderPhone: _currentOrder.phone,
      customerUid: _currentOrder.uuid,
    );
    if (!mounted) return;
    setState(() {
      _customerPhone = VendorOrderDisplay.formatPhone(phone);
    });
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
      await _orderService.acceptOrder(
        _currentOrder.id,
        vendorId: widget.vendor.id,
      );
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted'),
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

  Future<void> _markPreparing() async {
    setState(() => _isLoading = true);
    try {
      await _orderService.markPreparing(_currentOrder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as preparing')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markReadyForPickup() async {
    setState(() => _isLoading = true);
    try {
      await _orderService.markReadyForPickup(_currentOrder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order ready — dispatching rider'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject order?'),
        content: const Text(
          'The customer will be notified and the order will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _orderService.rejectOrder(
        _currentOrder.id,
        vendorId: widget.vendor.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _resolvedStatus() {
    return OrderLifecycle.resolveStatus({
      'status': _currentOrder.modernStatus,
      'order_status': _currentOrder.orderStatus,
      'isCancelled': _currentOrder.isCancelled,
      'isDelivered': _currentOrder.isDelivered,
    });
  }

  String _formatDate(String dateString) =>
      VendorOrderDisplay.formatTimestamp(dateString);

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
    return StreamBuilder<OrderModel?>(
      stream: _orderService.watchOrderById(widget.order.id),
      initialData: _currentOrder,
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          _currentOrder = snap.data!;
        }
        return _buildBody(context);
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    final vendorProducts = _currentOrder.products.where((p) => p.vendorId == widget.vendor.id).toList();
    final orderTotal = _currentOrder.billTotals.grandTotal;
    final statusId = _resolvedStatus();
    final canReject = OrderLifecycle.isPendingVendorAction(statusId);
    final canAssignRider = OrderLifecycle.canAssignRider(statusId) &&
        _currentOrder.deliveryBoyId.isEmpty;
    final statusLabel = OrderLifecycle.legacyLabel(statusId);

    return Scaffold(
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
                            color: _getStatusColor(statusLabel).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(statusLabel),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(statusLabel),
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
                    if (canReject) ...[
                      AppSpacing.h20,
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _rejectOrder,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (canAssignRider) ...[
                      AppSpacing.h15,
                      Text(
                        'Assign a delivery partner from the orders list, or open Assign Rider from the order card.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.35,
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
                      value: _customerPhone.isNotEmpty
                          ? _customerPhone
                          : 'Not available',
                    ),
                    AppSpacing.h15,
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: _currentOrder.address,
                    ),
                    if (_currentOrder.hasCustomerCoordinates ||
                        _currentOrder.address.trim().isNotEmpty) ...[
                      AppSpacing.h15,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final point = _currentOrder.customerCoordinates;
                            final ok = await ExternalNavigation.open(
                              lat: point?.latitude,
                              lng: point?.longitude,
                              address: _currentOrder.address,
                              coordinatesOnly: point == null,
                            );
                            if (!context.mounted || ok) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not open maps for customer location.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('View Customer Location'),
                        ),
                      ),
                    ],
                    if (widget.vendor.shopLat != null &&
                        widget.vendor.shopLng != null &&
                        GpsPoint.isValidCoord(
                          widget.vendor.shopLat,
                          widget.vendor.shopLng,
                        )) ...[
                      AppSpacing.h10,
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => ExternalNavigation.open(
                            lat: widget.vendor.shopLat,
                            lng: widget.vendor.shopLng,
                            coordinatesOnly: true,
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('View Store Location'),
                        ),
                      ),
                    ],
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
                                  Builder(
                                    builder: (_) {
                                      return Column(
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
                                          Text(
                                            product.quantityLabel,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          AppSpacing.h5,
                                          if (product.hasLineDiscount)
                                            Text(
                                              'MRP ₹${product.mrpLineTotal.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          Text(
                                            '₹${product.lineTotal.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (product.hasLineDiscount)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD1EEDB),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Saved ₹${product.lineDiscount.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF2E7D32),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
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
                child: Builder(
                  builder: (context) {
                    final bill = _currentOrder.billTotals;
                    bill.debugLog(tag: 'vendor-order-detail');
                    final mrpTotal = _currentOrder.products.fold<double>(
                      0,
                      (sum, p) =>
                          sum +
                          ((p.slashedPrice > p.price ? p.slashedPrice : p.price) *
                              p.itemCount),
                    );
                    final productDiscount =
                        (mrpTotal - bill.subtotal).clamp(0.0, double.infinity);
                    return Column(
                  children: [
                    _SummaryRow(
                      label: 'MRP Total',
                      value: '₹${mrpTotal.toStringAsFixed(2)}',
                    ),
                    if (productDiscount > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Product Discount',
                        value: '- ₹${productDiscount.toStringAsFixed(2)}',
                      ),
                    ],
                    AppSpacing.h10,
                    _SummaryRow(
                      label: 'Item Total',
                      value: '₹${bill.subtotal.toStringAsFixed(2)}',
                    ),
                    if (bill.couponDiscount > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Coupon discount',
                        value: '- ₹${bill.couponDiscount.toStringAsFixed(2)}',
                      ),
                    ],
                    AppSpacing.h10,
                    _SummaryRow(
                      label: 'Delivery Fee',
                      value: '₹${bill.deliveryFee.toStringAsFixed(2)}',
                    ),
                    if (bill.handlingCharge > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Handling Fee',
                        value: '₹${bill.handlingCharge.toStringAsFixed(2)}',
                      ),
                    ],
                    if (bill.platformFee > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Platform Fee',
                        value: '₹${bill.platformFee.toStringAsFixed(2)}',
                      ),
                    ],
                    if (bill.tax > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Tax',
                        value: '₹${bill.tax.toStringAsFixed(2)}',
                      ),
                    ],
                    if (bill.codConvenienceFee > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: bill.codFeeDescription.isNotEmpty
                            ? bill.codFeeDescription
                            : 'COD Convenience Fee',
                        value:
                            '₹${bill.codConvenienceFee.toStringAsFixed(2)}',
                      ),
                    ],
                    if (bill.deliveryPartnerTip > 0) ...[
                      AppSpacing.h10,
                      _SummaryRow(
                        label: 'Delivery Partner Tip',
                        value: '₹${bill.deliveryPartnerTip.toStringAsFixed(2)}',
                      ),
                    ],
                    AppSpacing.h15,
                    Divider(color: Colors.grey[300]),
                    AppSpacing.h15,
                    _SummaryRow(
                      label: 'Total Order Amount',
                      value: '₹${bill.grandTotal.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    AppSpacing.h15,
                    Divider(color: Colors.grey[300]),
                    AppSpacing.h15,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.1),
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
                            '₹${orderTotal.toStringAsFixed(2)}',
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
                    );
                  },
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
                  'Invoice',
                  style: TextStyle(
                    fontSize: 15,
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
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        AppSpacing.w15,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              AppSpacing.h5,
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: FontWeight.w700,
            color: isTotal ? AppColor.primary : onSurface,
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

