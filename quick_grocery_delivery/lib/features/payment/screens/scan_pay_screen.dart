import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({super.key});

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen>
    with SingleTickerProviderStateMixin {
  final _orderIdController = TextEditingController();
  final _amountController = TextEditingController();
  bool _verified = false;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _amountController.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _showQr() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Receive payment',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Image.asset('assets/images/qr.png'),
              const SizedBox(height: 12),
              const Text('Ask customer to scan this UPI QR'),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPayment() {
    final orderId = _orderIdController.text.trim();
    final amount = _amountController.text.trim();
    if (orderId.isEmpty || amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter order ID and amount')),
      );
      return;
    }
    setState(() => _verified = true);
    _anim.forward(from: 0);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment verified successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Pay')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: GlobalVariables.primary,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _showQr,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Image.asset(AppIcons.scan, height: 40, width: 40),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show payment QR',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text('Customer scans to pay'),
                        ],
                      ),
                    ),
                    const Icon(Icons.qr_code_2, size: 40),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment verification',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _orderIdController,
            decoration: InputDecoration(
              labelText: 'Order ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount received (₹)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _verifyPayment,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verify payment'),
          ),
          if (_verified) ...[
            const SizedBox(height: 24),
            ScaleTransition(
              scale: CurvedAnimation(parent: _anim, curve: Curves.elasticOut),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
            const Center(
              child: Text(
                'Payment linked to order',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Recent payments',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.payments_outlined),
              title: Text('COD collection'),
              subtitle: Text('Mark verified after collecting cash or UPI'),
            ),
          ),
        ],
      ),
    );
  }
}
