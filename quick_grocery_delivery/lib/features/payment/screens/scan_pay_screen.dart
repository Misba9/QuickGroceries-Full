import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/features/payment/screens/order_collect_payment_screen.dart';
import 'package:quick_grocery_delivery/features/payment/services/payment_collection_orders_service.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// COD payment collection queue — Firestore `createdAt` DESC, real-time tabs.
class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _ordersService = PaymentCollectionOrdersService();
  String? _riderId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadRiderId();
  }

  Future<void> _loadRiderId() async {
    final pref = await SharedPreferences.getInstance();
    final id = pref.getString('deliveryBoyId') ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
    if (!mounted) return;
    setState(() => _riderId = id);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Collect Payment'),
        backgroundColor: GlobalVariables.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(text: 'Pending Collection'),
            Tab(text: 'Collected'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _riderId == null
          ? const _PaymentCenterMessage(
              message: 'Loading payments...',
              showSpinner: true,
            )
          : _riderId!.isEmpty
              ? const _PaymentCenterMessage(
                  message: 'Sign in to view payment collection orders.',
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _PaymentCollectionList(
                      riderId: _riderId!,
                      filter: PaymentCollectionFilter.pending,
                      ordersService: _ordersService,
                    ),
                    _PaymentCollectionList(
                      riderId: _riderId!,
                      filter: PaymentCollectionFilter.collected,
                      ordersService: _ordersService,
                    ),
                    _PaymentCollectionList(
                      riderId: _riderId!,
                      filter: PaymentCollectionFilter.all,
                      ordersService: _ordersService,
                    ),
                  ],
                ),
    );
  }
}

class _PaymentCollectionList extends StatelessWidget {
  const _PaymentCollectionList({
    required this.riderId,
    required this.filter,
    required this.ordersService,
  });

  final String riderId;
  final PaymentCollectionFilter filter;
  final PaymentCollectionOrdersService ordersService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PaymentCollectionListState>(
      stream: ordersService.watchState(riderId: riderId, filter: filter),
      builder: (context, snap) {
        final state = snap.data;

        if (state is PaymentCollectionLoading || state == null) {
          return const _PaymentCenterMessage(
            message: 'Loading payments...',
            showSpinner: true,
          );
        }

        if (state is PaymentCollectionUnavailable) {
          return const _PaymentCenterMessage(
            message: 'Payment data is temporarily unavailable',
            icon: Icons.cloud_off_outlined,
          );
        }

        if (state is! PaymentCollectionLoaded) {
          return const _PaymentCenterMessage(
            message: 'Payment data is temporarily unavailable',
            icon: Icons.cloud_off_outlined,
          );
        }

        final orders = state.orders;
        if (orders.isEmpty) {
          return const _PaymentCenterMessage(
            message: 'No payments found',
            icon: Icons.receipt_long_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final order = orders[i];
            return _PaymentCollectionOrderCard(
              order: order,
              onTap: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderCollectPaymentScreen(order: order),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PaymentCenterMessage extends StatelessWidget {
  const _PaymentCenterMessage({
    required this.message,
    this.showSpinner = false,
    this.icon,
  });

  final String message;
  final bool showSpinner;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ] else if (icon != null) ...[
              Icon(icon, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                height: 1.4,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCollectionOrderCard extends StatelessWidget {
  const _PaymentCollectionOrderCard({
    required this.order,
    required this.onTap,
  });

  final OrderModel order;
  final VoidCallback onTap;

  static String _shortId(String id) {
    if (id.length <= 6) return id.toUpperCase();
    return id.substring(id.length - 6).toUpperCase();
  }

  static String _createdLabel(OrderModel order) {
    final dt = order.createdAt;
    if (dt != null) return DateFormat.jm().format(dt);
    final legacy = order.createdDate.trim();
    if (legacy.isEmpty) return '—';
    final parsed = DateTime.tryParse(legacy);
    if (parsed != null) return DateFormat.jm().format(parsed);
    return legacy;
  }

  static String _statusLabel(OrderModel order) {
    if (order.payment.isPaymentCollected) return 'Collected';
    return 'Pending Collection';
  }

  @override
  Widget build(BuildContext context) {
    final amount = order.payment.orderTotal;
    final pending = order.payment.requiresCodCollection;
    final statusColor = pending ? Colors.orange.shade800 : Colors.green.shade800;
    final statusBg = pending ? Colors.orange.shade50 : Colors.green.shade50;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName.isEmpty
                          ? 'Customer'
                          : order.customerName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: GlobalVariables.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${_shortId(order.id)}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _createdLabel(order),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(order),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
