import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';

class CustomerSummaryCards extends StatelessWidget {
  const CustomerSummaryCards({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.select<CustomerAdminService, CustomerListSummary>(
      (svc) => svc.summary,
    );
    final currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

    final items = [
      _Item('Total customers', '${s.totalCustomers}', Icons.people_outline),
      _Item('Active today', '${s.activeToday}', Icons.bolt_outlined),
      _Item('New today', '${s.newToday}', Icons.person_add_alt_1),
      _Item('Online now', '${s.onlineNow}', Icons.wifi_tethering),
      _Item('Total revenue', currency.format(s.totalRevenue), Icons.payments_outlined),
      _Item('Repeat buyers', '${s.repeatBuyers}', Icons.repeat),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 1100 ? 6 : (c.maxWidth > 700 ? 3 : 2);
        final w = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((e) => SizedBox(width: w.clamp(140, 220), child: _Card(e)))
              .toList(),
        );
      },
    );
  }
}

class _Item {
  const _Item(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _Card extends StatelessWidget {
  const _Card(this.item);
  final _Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 18, color: const Color(0xFF1D4ED8)),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            item.label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
