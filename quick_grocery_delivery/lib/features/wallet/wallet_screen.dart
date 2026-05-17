import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';
import 'package:quick_grocery_delivery/widgets/driver_stat_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    final p = context.read<DriverProfileService>().profile;
    if (p == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    try {
      await context.read<DriverProfileService>().requestWithdrawal(amount);
      _amountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DriverProfileService>().profile;

    return Scaffold(
      backgroundColor: GlobalVariables.background,
      appBar: AppBar(
        title: const Text('Wallet', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: GlobalVariables.background,
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<DriverProfileService>().refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DriverStatCard(
                    label: 'Wallet balance',
                    value: '₹${profile.walletBalance.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    subtitle: 'Pending payout ₹${profile.pendingPayout.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DriverStatCard(
                          label: 'Total earned',
                          value: '₹${profile.totalEarnings.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DriverStatCard(
                          label: 'Incentives',
                          value: '₹${profile.incentivesTotal.toStringAsFixed(0)}',
                          icon: Icons.card_giftcard_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Request withdrawal',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount (₹)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _withdraw,
                            child: const Text('Submit request'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Transaction history',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: context.read<DriverProfileService>().watchWalletTransactions(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snap.data!;
                      if (items.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No transactions yet'),
                        );
                      }
                      return Column(
                        children: items.map((t) {
                          final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                          final type = t['type']?.toString() ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: amount >= 0 ? Colors.green : Colors.red,
                              ),
                              title: Text(type.replaceAll('_', ' ')),
                              subtitle: Text(t['note']?.toString() ?? ''),
                              trailing: Text(
                                '${amount >= 0 ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: amount >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
