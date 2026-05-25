import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';
import 'package:quick_grocery_admin/view/customers/services/customer_admin_service.dart';
import 'package:quick_grocery_admin/view/orders/screens/order_details_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.enriched,
    this.initialTab = 0,
  });

  final CustomerEnriched enriched;
  final int initialTab;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    final uid = widget.enriched.customer.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerAdminService>().loadProfile(uid);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.enriched.customer;
    final stats = widget.enriched.stats;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(c.name.isEmpty ? 'Customer' : c.name),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'User info'),
            Tab(text: 'Orders'),
            Tab(text: 'Addresses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _infoTab(c, stats, currency),
          _ordersTab(),
          _addressesTab(),
        ],
      ),
    );
  }

  Widget _infoTab(CustomerModel c, CustomerOrderStats stats, NumberFormat currency) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        c.image.isNotEmpty ? NetworkImage(c.image) : null,
                    child: c.image.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(c.phoneNumber),
                        Text(c.email),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              _row('User ID', widget.enriched.displayId),
              _row('Joined', _fmt(c.createdAtTs)),
              _row('Last active', _fmt(c.lastActiveTs ?? stats.lastOrderAt)),
              _row('Total orders', '${stats.totalOrders}'),
              _row('Delivered orders', '${stats.completedOrders}'),
              _row('Total spend', currency.format(stats.totalSpend)),
              _row('Status', c.isBlocked ? 'Blocked' : 'Active'),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final svc = context.read<CustomerAdminService>();
                      await svc.setBlocked(
                        widget.enriched.displayId,
                        !c.isBlocked,
                      );
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    icon: Icon(c.isBlocked ? Icons.lock_open : Icons.block),
                    label: Text(c.isBlocked ? 'Unblock' : 'Block'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ordersTab() {
    return Consumer<CustomerAdminService>(
      builder: (context, svc, _) {
        if (svc.profileLoading || svc.profileOrders == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = svc.profileOrders!;
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final o = orders[i];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              title: Text('#${o.id}'),
              subtitle: Text('${o.orderStatus} · ₹${o.getTotalAmount().toStringAsFixed(0)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailsScreen(order: o),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _addressesTab() {
    return Consumer<CustomerAdminService>(
      builder: (context, svc, _) {
        if (svc.profileLoading || svc.profileAddresses == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = svc.profileAddresses!;
        if (list.isEmpty) {
          return const Center(child: Text('No saved addresses'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final a = list[i];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              title: Text(a.type),
              subtitle: Text('${a.name} · ${a.mobile}\n${a.area}'),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, y · HH:mm').format(dt);
  }
}
