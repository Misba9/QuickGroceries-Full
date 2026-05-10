import 'package:quick_grocery_delivery/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/features/orders/services/order_service.dart';
import 'package:provider/provider.dart';

class UpdateOrderStatusDialog extends StatefulWidget {
  const UpdateOrderStatusDialog({
    super.key,
    required this.id,
    required this.customerID,
  });
  final String id;
  final String customerID;
  @override
  _UpdateOrderStatusDialogState createState() =>
      _UpdateOrderStatusDialogState();
}

class _UpdateOrderStatusDialogState extends State<UpdateOrderStatusDialog> {
  String _selectedStatus = 'Going to Shop';

  final List<String> _statusOptions = [
    'Going to Shop',
    'Order Picked',
    'On the Way',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Order Status'),
      content: Consumer<OrderService>(
        builder: (context, p, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (newStatus) {
                  p.sendFCMMessage(widget.customerID, newStatus!);
                  p.onStatusChanged(newStatus ?? "");
                  setState(() {
                    _selectedStatus = newStatus!;
                  });
                  p.getOrders();
                },
                decoration: const InputDecoration(
                  labelText: 'Select Status',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        Consumer<OrderService>(
          builder: (context, p, _) {
            return ElevatedButton(
              onPressed: () {
                p.updateStatus(_selectedStatus, widget.id);
                if (_selectedStatus == 'Order Delivered') {
                  p.completeOrder(context, widget.id);
                }
                // Handle the status update logic here
                print('Status updated to $_selectedStatus');

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Status updated'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
              child: const Text('Update'),
            );
          },
        ),
      ],
    );
  }
}

// To use the dialog, you can call this function in your widget tree
void showUpdateStatusDialog(
  BuildContext context,
  String id,
  String customerID,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return UpdateOrderStatusDialog(id: id, customerID: customerID);
    },
  );
}
