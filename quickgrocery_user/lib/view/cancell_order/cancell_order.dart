import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/database/cancel_resons.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/cancell_order/cancel_succes_screen.dart';
import 'package:quickgrocery/view/orders/services/order_cancel_api.dart';

class CancelOrder extends StatefulWidget {
  const CancelOrder({super.key, required this.id});
  final String id;

  @override
  State<CancelOrder> createState() => _CancelOrderState();
}

class _CancelOrderState extends State<CancelOrder> {
  int _selectedIndex = 0;
  final _otherReasonController = TextEditingController();
  final _cancelApi = OrderCancelApi();
  bool _submitting = false;

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  String get _reason {
    if (_selectedIndex == cancelSnap.length - 1) {
      return _otherReasonController.text.trim();
    }
    return cancelSnap[_selectedIndex]['resone']?.toString() ?? '';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _cancelApi.cancelByCustomer(
        orderId: widget.id,
        reason: _reason.isEmpty ? null : _reason,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CancellSuccesScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(e.toString(), context: context);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cancelSnap.length,
                  itemBuilder: (context, i) {
                    return FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: ResoneTile(
                        resone: cancelSnap[i]['resone'],
                        isSelected: _selectedIndex == i,
                        onTap: (s) {
                          setState(() {
                            _selectedIndex = i;
                          });
                        },
                      ),
                    );
                  },
                ),
                const Text(
                  'Others',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFEFEFF0),
                  ),
                  child: TextFormField(
                    controller: _otherReasonController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Others reason...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(15.0),
        child: PrimaryButton(
          label: _submitting ? 'Cancelling...' : 'Submit',
          onTap: _submitting ? null : _submit,
        ),
      ),
    );
  }
}

class ResoneTile extends StatelessWidget {
  const ResoneTile({
    super.key,
    required this.resone,
    required this.isSelected,
    required this.onTap,
  });
  final String resone;
  final bool isSelected;
  final Function(bool? l) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Radio(
              focusColor: Colors.black,
              activeColor: Colors.black,
              value: isSelected,
              groupValue: true,
              onChanged: onTap,
            ),
            const SizedBox(width: 10),
            Text(
              resone,
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
