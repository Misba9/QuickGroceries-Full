import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Real-time payment collection breakdown from recent orders.
class PaymentCollectionStatsCard extends StatefulWidget {
  const PaymentCollectionStatsCard({super.key});

  @override
  State<PaymentCollectionStatsCard> createState() =>
      _PaymentCollectionStatsCardState();
}

class _PaymentCollectionStatsCardState extends State<PaymentCollectionStatsCard> {
  bool _loading = true;
  int _onlinePaid = 0;
  int _codCash = 0;
  int _codUpi = 0;
  int _pendingCollection = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(300)
          .get();

      int online = 0, cash = 0, upi = 0, pending = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final method =
            (d['paymentMethod'] ?? d['payment_method'] ?? 'cod').toString().toLowerCase();
        final status =
            (d['paymentStatus'] ?? d['payment_status'] ?? '').toString().toLowerCase();
        final paid = d['isPaid'] == true || status == 'paid';
        final collection =
            (d['collectionMethod'] ?? d['collection_method'] ?? '').toString().toLowerCase();

        if (method == 'cod' && !paid) {
          pending++;
          continue;
        }
        if (paid && method != 'cod' && method != 'cash_on_delivery') {
          online++;
        } else if (paid && collection == 'cash') {
          cash++;
        } else if (paid && collection == 'upi') {
          upi++;
        }
      }

      if (mounted) {
        setState(() {
          _onlinePaid = online;
          _codCash = cash;
          _codUpi = upi;
          _pendingCollection = pending;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment collection (last 300 orders)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _chip('Online paid', _onlinePaid, Colors.green),
                  _chip('COD · Cash', _codCash, Colors.blue),
                  _chip('COD · UPI', _codUpi, Colors.indigo),
                  _chip('Pending collection', _pendingCollection, Colors.orange),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color)),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
