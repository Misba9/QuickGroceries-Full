import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

/// Bottom sheet for rider to enter the 4-digit customer delivery OTP.
Future<String?> showDeliveryOtpSheet(
  BuildContext context, {
  String? customerName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: _DeliveryOtpSheetBody(customerName: customerName),
    ),
  );
}

class _DeliveryOtpSheetBody extends StatefulWidget {
  const _DeliveryOtpSheetBody({this.customerName});

  final String? customerName;

  @override
  State<_DeliveryOtpSheetBody> createState() => _DeliveryOtpSheetBodyState();
}

class _DeliveryOtpSheetBodyState extends State<_DeliveryOtpSheetBody> {
  final _controller = TextEditingController();
  String _otp = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 4-digit code from customer')),
      );
      return;
    }
    Navigator.pop(context, _otp);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customerName?.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter delivery OTP',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          name != null && name.isNotEmpty
              ? 'Ask $name for the 4-digit code sent to their app.'
              : 'Ask the customer for the 4-digit code sent to their app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        PinCodeTextField(
          appContext: context,
          length: 4,
          controller: _controller,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(12),
            fieldHeight: 56,
            fieldWidth: 56,
            activeColor: GlobalVariables.primary,
            selectedColor: GlobalVariables.primary,
            inactiveColor: Colors.grey.shade300,
          ),
          onChanged: (v) => _otp = v,
          onCompleted: (v) {
            _otp = v;
            _submit();
          },
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Verify & mark delivered'),
        ),
      ],
    );
  }
}
