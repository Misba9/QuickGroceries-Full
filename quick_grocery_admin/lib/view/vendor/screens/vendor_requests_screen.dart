import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/core/layout/admin_page_wrapper.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/vendor_request_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/products/screens/product_details_screen.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_request_service.dart';

class VendorRequestsScreen extends StatefulWidget {
  const VendorRequestsScreen({super.key});

  @override
  State<VendorRequestsScreen> createState() => _VendorRequestsScreenState();
}

class _VendorRequestsScreenState extends State<VendorRequestsScreen> {
  static final _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VendorRequestService>().clearMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<VendorRequestService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icons/userplus.svg'),
                    AppSpacing.w10,
                    const Expanded(
                      child: Text(
                        'Vendor Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.h10,
                Text(
                  'Review signup applications. Approve to create Firebase Auth + vendor profile.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                AppSpacing.h15,
                _FilterChips(service: service),
                if (service.actionMessage != null) ...[
                  AppSpacing.h10,
                  _Banner(
                    text: service.actionMessage!,
                    color: Colors.green.shade50,
                    border: Colors.green.shade200,
                    textColor: Colors.green.shade900,
                    onDismiss: service.clearMessages,
                  ),
                ],
                if (service.actionError != null) ...[
                  AppSpacing.h10,
                  _Banner(
                    text: service.actionError!,
                    color: Colors.red.shade50,
                    border: Colors.red.shade200,
                    textColor: Colors.red.shade900,
                    onDismiss: service.clearMessages,
                  ),
                ],
                AppSpacing.h15,
                WrapperWidget(
                  child: StreamBuilder<List<VendorRequestModel>>(
                    stream: service.watchRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const AdminBoundedCenter(
                          minHeight: 200,
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          debugPrint(
                            '[VendorRequestsScreen] stream error: ${snapshot.error}',
                          );
                        }
                        return AdminBoundedCenter(
                          minHeight: 200,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade400,
                                size: 40,
                              ),
                              AppSpacing.h10,
                              Text(
                                'Failed to load vendor requests.',
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                              AppSpacing.h5,
                              Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final all = snapshot.data ?? [];
                      final rows = service.filtered(all);
                      if (rows.isEmpty) {
                        return const AdminBoundedCenter(
                          minHeight: 200,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No Vendor Requests Found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'New signup applications will appear here.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, c) {
                          final colSpace =
                              (c.maxWidth * 0.02).clamp(8.0, 20.0);
                          final dataTable = DataTable(
                            columnSpacing: colSpace,
                            dataRowMinHeight: 72,
                            dataRowMaxHeight: 88,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'SL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Vendor Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Shop Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Phone',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Email',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Date',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Actions',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: [
                              for (var i = 0; i < rows.length; i++)
                                _row(context, service, rows[i], i + 1),
                            ],
                          );
                          return adminScrollableDataTable(
                            viewportWidth: c.maxWidth,
                            minTableWidth: 1100,
                            dataTable: dataTable,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(
    BuildContext context,
    VendorRequestService service,
    VendorRequestModel r,
    int sl,
  ) {
    return DataRow(
      cells: [
        DataCell(Text('$sl')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _thumb(r.vendorImage),
              AppSpacing.w10,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  r.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _thumb(r.shopLogo),
              AppSpacing.w10,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  r.shopName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(r.phone)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              r.email,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_StatusChip(status: r.status)),
        DataCell(
          Text(
            r.createdAt != null ? _dateFormat.format(r.createdAt!) : '—',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
        DataCell(
          service.isActionLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ActionBtn(
                      label: 'View Details',
                      onTap: () => _showDetail(context, r, service),
                    ),
                    if (r.isPending) ...[
                      _ActionBtn(
                        label: 'Approve',
                        color: AppColor.primary,
                        onTap: () => _confirmApprove(context, service, r),
                      ),
                      _ActionBtn(
                        label: 'Reject',
                        color: Colors.red.shade400,
                        onTap: () => _rejectDialog(context, service, r),
                      ),
                    ],
                    if (!r.isPending)
                      _ActionBtn(
                        label: 'Delete',
                        color: Colors.grey.shade700,
                        onTap: () => _confirmDelete(context, service, r),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _thumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.store, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 40,
          height: 40,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 18),
        ),
      ),
    );
  }

  Future<void> _confirmApprove(
    BuildContext context,
    VendorRequestService service,
    VendorRequestModel r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve vendor?'),
        content: Text(
          'Create Firebase Auth account and vendor profile for ${r.fullName} (${r.email})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await service.approve(r.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.actionMessage ?? 'Vendor approved successfully',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else if (service.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.actionError!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _rejectDialog(
    BuildContext context,
    VendorRequestService service,
    VendorRequestModel r,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Reject', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await service.reject(
      r.id,
      controller.text.trim().isEmpty
          ? 'Rejected by admin'
          : controller.text.trim(),
    );
    controller.dispose();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.actionMessage ?? 'Vendor request rejected.',
          ),
        ),
      );
    } else if (service.actionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(service.actionError!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VendorRequestService service,
    VendorRequestModel r,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: Text('Remove signup request for ${r.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await service.deleteRequest(r.id);
  }

  void _showDetail(
    BuildContext context,
    VendorRequestModel r,
    VendorRequestService service,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(r.fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.vendorImage.isNotEmpty)
                Center(child: Image.network(r.vendorImage, height: 80)),
              AppSpacing.h10,
              _detailRow('Email', r.email),
              _detailRow('Phone', r.phone),
              _detailRow('Shop', r.shopName),
              _detailRow('Address', r.shopAddress),
              _detailRow('Status', r.status),
              if (r.createdAt != null)
                _detailRow('Submitted', _dateFormat.format(r.createdAt!)),
              if (r.authUid != null) _detailRow('Auth UID', r.authUid!),
              if (r.rejectionReason != null)
                _detailRow('Rejection', r.rejectionReason!),
              if (r.shopLogo.isNotEmpty) ...[
                AppSpacing.h10,
                const Text(
                  'Shop logo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Image.network(r.shopLogo, height: 64),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          if (r.isPending)
            ElevatedButton(
              onPressed: service.isActionLoading
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _confirmApprove(context, service, r);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.service});
  final VendorRequestService service;

  @override
  Widget build(BuildContext context) {
    const filters = ['all', 'pending', 'approved', 'rejected', 'blocked'];
    return Wrap(
      spacing: 8,
      children: [
        for (final f in filters)
          FilterChip(
            label: Text(f[0].toUpperCase() + f.substring(1)),
            selected: service.filterStatus == f,
            onSelected: (_) => service.setFilter(f),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case 'pending':
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case 'approved':
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
      case 'rejected':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
      case 'blocked':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? Colors.black87,
        side: BorderSide(color: color ?? Colors.grey.shade400),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.color,
    required this.border,
    required this.textColor,
    required this.onDismiss,
  });

  final String text;
  final Color color;
  final Color border;
  final Color textColor;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(color: textColor))),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
