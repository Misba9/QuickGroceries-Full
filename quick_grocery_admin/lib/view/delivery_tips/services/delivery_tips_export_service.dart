import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/view/delivery_tips/models/delivery_tips_settings_model.dart';
import 'package:quick_grocery_admin/view/orders/services/orders_export_download_stub.dart'
    if (dart.library.html) 'package:quick_grocery_admin/view/orders/services/orders_export_download_web.dart';

class DeliveryTipsExportService {
  static String _fmt(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(d);

  static Future<void> exportCsv(
    BuildContext context,
    List<DeliveryTipReportRow> rows, {
    String filename = 'delivery_tips_export',
  }) async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tip records to export')),
      );
      return;
    }
    final data = [
      [
        'Order ID',
        'Customer Name',
        'Delivery Partner',
        'Tip Amount',
        'Date',
        'Status',
      ],
      ...rows.map(
        (r) => [
          r.orderId,
          r.customerName,
          r.deliveryPartnerName.isNotEmpty
              ? r.deliveryPartnerName
              : r.deliveryPartnerId,
          r.tipAmount.toStringAsFixed(2),
          _fmt(r.createdAt),
          r.tipStatus,
        ],
      ),
    ];
    final csv = const ListToCsvConverter().convert(data);
    final name =
        '${filename}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    downloadCsvBytes(name, utf8.encode(csv));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export downloaded')),
      );
    }
  }

  static Future<void> exportExcel(
    BuildContext context,
    List<DeliveryTipReportRow> rows,
  ) async {
    await exportCsv(context, rows, filename: 'delivery_tips_export');
  }
}
