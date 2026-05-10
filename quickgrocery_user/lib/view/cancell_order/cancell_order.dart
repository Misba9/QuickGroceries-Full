import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/database/cancel_resons.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:quickgrocery/view/cancell_order/cancel_succes_screen.dart';
import 'package:quickgrocery/view/orders/services/order_service.dart';
import 'package:provider/provider.dart';

class CancelOrder extends StatefulWidget {
  const CancelOrder({super.key, required this.id});
  final String id;

  @override
  State<CancelOrder> createState() => _CancelOrderState();
}

class _CancelOrderState extends State<CancelOrder> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderService>(context);

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
          label: 'Submit',
          onTap: () {
            provider.cancellOrder(context, widget.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CancellSuccesScreen(),
              ),
            );
          },
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
