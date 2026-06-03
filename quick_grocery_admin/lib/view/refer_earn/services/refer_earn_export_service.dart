import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/view/orders/services/orders_export_download_stub.dart'
    if (dart.library.html) 'package:quick_grocery_admin/view/orders/services/orders_export_download_web.dart';
import 'package:quick_grocery_admin/view/refer_earn/models/referral_record_model.dart';

class ReferEarnExportService {
  static String _fmt(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd HH:mm').format(d);

  static Future<void> exportReferralsCsv(
    BuildContext context,
    List<ReferralRecordModel> rows, {
    String filename = 'referrals_export',
  }) async {
    if (rows.isEmpty) {
      _snack(context, 'No referrals to export');
      return;
    }

    final data = [
      [
        'Referral ID',
        'Referrer Name',
        'Referrer Phone',
        'Referral Code',
        'Referred User',
        'Referred Phone',
        'Signup Date',
        'First Order Amount',
        'Status',
        'Reward Status',
      ],
      ...rows.map(
        (r) => [
          r.id,
          r.referrerName,
          r.referrerPhone,
          r.referrerCode,
          r.referredUserName,
          r.referredUserPhone,
          _fmt(r.signupDate ?? r.referralDate),
          r.firstOrderAmount?.toStringAsFixed(2) ?? '',
          r.statusLabel,
          r.rewardStatus,
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(data);
    final name =
        '${filename}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    downloadCsvBytes(name, utf8.encode(csv));
    _snack(context, 'Export downloaded');
  }

  static Future<void> exportReferralsExcel(
    BuildContext context,
    List<ReferralRecordModel> rows,
  ) =>
      exportReferralsCsv(context, rows, filename: 'referrals_excel');

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
