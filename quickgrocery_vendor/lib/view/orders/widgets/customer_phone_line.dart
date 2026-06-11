import 'package:flutter/material.dart';

import '../../../services/customer_phone_resolver.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/vendor_order_display.dart';

/// Shows customer phone on order cards, falling back to profile lookup.
class CustomerPhoneLine extends StatefulWidget {
  const CustomerPhoneLine({
    super.key,
    required this.orderPhone,
    required this.customerUid,
    this.iconSize = 16,
    this.fontSize = 14,
  });

  final String orderPhone;
  final String customerUid;
  final double iconSize;
  final double fontSize;

  @override
  State<CustomerPhoneLine> createState() => _CustomerPhoneLineState();
}

class _CustomerPhoneLineState extends State<CustomerPhoneLine> {
  String _display = '';

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  @override
  void didUpdateWidget(covariant CustomerPhoneLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderPhone != widget.orderPhone ||
        oldWidget.customerUid != widget.customerUid) {
      _loadPhone();
    }
  }

  Future<void> _loadPhone() async {
    final direct = VendorOrderDisplay.formatPhone(widget.orderPhone);
    if (direct.isNotEmpty) {
      if (mounted) setState(() => _display = direct);
      return;
    }

    final resolved = await CustomerPhoneResolver.resolve(
      orderPhone: widget.orderPhone,
      customerUid: widget.customerUid,
    );
    if (!mounted) return;
    setState(() {
      _display = VendorOrderDisplay.formatPhone(resolved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final available = _display.isNotEmpty;
    return Row(
      children: [
        Icon(Icons.phone_outlined, size: widget.iconSize, color: Colors.grey[600]),
        AppSpacing.w10,
        Text(
          available ? _display : 'Phone not available',
          style: TextStyle(
            fontSize: widget.fontSize,
            color: available ? Colors.grey[800] : Colors.grey[500],
            fontStyle: available ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
