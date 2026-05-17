import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/services/invoice_service.dart';
import 'package:quick_grocery_admin/view/orders/services/orders_export_download_stub.dart'
    if (dart.library.html) 'package:quick_grocery_admin/view/orders/services/orders_export_download_web.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_status_utils.dart';

/// CSV / print export for orders list (web admin).
class OrdersExportService {
  OrdersExportService._();

  static Future<void> exportCsv(
    BuildContext context,
    List<OrderModel> orders, {
    String filename = 'orders_export',
  }) async {
    if (orders.isEmpty) {
      _snack(context, 'No orders to export');
      return;
    }

    final rows = <List<dynamic>>[
      [
        'Order ID',
        'Date',
        'Customer',
        'Phone',
        'Status',
        'Payment',
        'Items',
        'Total (INR)',
        'Delivery charge',
      ],
      ...orders.map((o) {
        final st = OrderStatusUtils.styleForOrder(o).label;
        return [
          o.id,
          o.createdDate,
          o.customerName,
          o.phone,
          st,
          o.isPaid ? 'Paid' : 'COD',
          o.products.length,
          o.getTotalAmount().toStringAsFixed(2),
          o.deliveryCharge,
        ];
      }),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final name =
        '${filename}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    if (kIsWeb) {
      downloadCsvBytes(name, utf8.encode(csv));
      _snack(context, 'Downloaded $name');
    } else {
      _snack(context, 'CSV export is available on web admin');
    }
  }

  /// Excel-friendly: same CSV bytes with .csv extension (opens in Excel).
  static Future<void> exportExcel(
    BuildContext context,
    List<OrderModel> orders,
  ) =>
      exportCsv(context, orders, filename: 'orders_excel');

  static Future<void> printOrder(
    BuildContext context,
    OrderModel order,
  ) async {
    await InvoiceService.printInvoice(
      order: order,
      context: context,
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
