import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_row_actions.dart';
import 'package:quick_grocery_admin/view/orders/widgets/order_status_badge.dart';

/// [PaginatedDataTable] source — one row per order, no duplicate layout code.
class OrdersDataTableSource extends DataTableSource {
  OrdersDataTableSource({
    required List<OrderModel> orders,
    required this.onView,
  }) : _orders = orders;

  List<OrderModel> _orders;
  final OrderDrawerCallback onView;

  void updateOrders(List<OrderModel> orders) {
    _orders = orders;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= _orders.length) return null;
    return buildDataRow(
      order: _orders[index],
      index: index,
      onView: onView,
    );
  }

  /// Builds a [DataRow] for [DataTable] (scroll-safe, no [PaginatedDataTable]).
  static DataRow buildDataRow({
    required OrderModel order,
    required int index,
    required OrderDrawerCallback onView,
  }) {
    final urgent = OrderEtaUtils.isDelayed(order);

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return const Color(0xFFFFF9E6);
        }
        if (urgent) return const Color(0xFFFFF1F2);
        return index.isEven ? Colors.white : const Color(0xFFFAFAFB);
      }),
      cells: [
        DataCell(_cellText(_shortId(order.id), bold: true)),
        DataCell(_customerCell(order)),
        DataCell(_cellText(_vendorLabel(order))),
        DataCell(_riderChip(order)),
        DataCell(_paymentChip(order)),
        DataCell(
          _cellText(
            '₹${order.getTotalAmount().toStringAsFixed(0)}',
            bold: true,
          ),
        ),
        DataCell(OrderStatusBadge(order: order, compact: true)),
        DataCell(_cellText(OrderEtaUtils.etaLabel(order))),
        DataCell(OrderRowActions(order: order, onView: onView)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _orders.length;

  @override
  int get selectedRowCount => 0;

  static String _shortId(String id) =>
      id.length > 10 ? '${id.substring(0, 10)}…' : id;

  static Widget _cellText(String text, {bool bold = false}) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  static Widget _customerCell(OrderModel o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          o.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Text(
          o.phone,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  static String _vendorLabel(OrderModel o) {
    if (o.products.isEmpty || o.products.first.vendorId.isEmpty) return '—';
    final v = o.products.first.vendorId;
    return v.length > 8 ? '${v.substring(0, 8)}…' : v;
  }

  static Widget _riderChip(OrderModel o) {
    final assigned = o.deliveryBoyId.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: assigned ? Colors.blue.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        assigned ? 'Assigned' : 'Unassigned',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: assigned ? Colors.blue.shade800 : Colors.orange.shade900,
        ),
      ),
    );
  }

  static Widget _paymentChip(OrderModel o) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: o.isPaid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        o.isPaid ? 'Online' : 'COD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: o.isPaid ? Colors.green.shade800 : Colors.orange.shade900,
        ),
      ),
    );
  }
}
