import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_delivery/models/delivery_boy_profile.dart';
import 'package:quick_grocery_delivery/services/driver_profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _licence;
  late final TextEditingController _vehicleType;
  late final TextEditingController _vehicleNumber;
  late final TextEditingController _bankName;
  late final TextEditingController _bankNumber;
  late final TextEditingController _ifsc;
  late final TextEditingController _upi;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<DriverProfileService>().profile!;
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone);
    _email = TextEditingController(text: p.email);
    _address = TextEditingController(text: p.address);
    _licence = TextEditingController(text: p.licence);
    _vehicleType = TextEditingController(text: p.vehicleType);
    _vehicleNumber = TextEditingController(text: p.vehicleNumber);
    _bankName = TextEditingController(text: p.bankAccountName);
    _bankNumber = TextEditingController(text: p.bankAccountNumber);
    _ifsc = TextEditingController(text: p.bankIfsc);
    _upi = TextEditingController(text: p.upiId);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _licence.dispose();
    _vehicleType.dispose();
    _vehicleNumber.dispose();
    _bankName.dispose();
    _bankNumber.dispose();
    _ifsc.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final current = context.read<DriverProfileService>().profile!;
      final updated = DeliveryBoyProfile(
        id: current.id,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        image: current.image,
        licence: _licence.text.trim(),
        createdAt: current.createdAt,
        isActive: current.isActive,
        isOnline: current.isOnline,
        pauseDeliveries: current.pauseDeliveries,
        walletBalance: current.walletBalance,
        totalEarnings: current.totalEarnings,
        pendingPayout: current.pendingPayout,
        driverRating: current.driverRating,
        totalDeliveries: current.totalDeliveries,
        completedOrders: current.completedOrders,
        rejectedOrders: current.rejectedOrders,
        incentivesTotal: current.incentivesTotal,
        vehicleType: _vehicleType.text.trim(),
        vehicleNumber: _vehicleNumber.text.trim(),
        bankAccountName: _bankName.text.trim(),
        bankAccountNumber: _bankNumber.text.trim(),
        bankIfsc: _ifsc.text.trim(),
        upiId: _upi.text.trim(),
        documents: current.documents,
        acceptanceRate: current.acceptanceRate,
        onTimePercent: current.onTimePercent,
        availability: current.availability,
      );
      await context.read<DriverProfileService>().updateProfile(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Full name', Icons.person_outline),
            _field(_phone, 'Phone', Icons.phone_outlined),
            _field(_email, 'Email', Icons.email_outlined),
            _field(_address, 'Address', Icons.home_outlined, maxLines: 2),
            _field(_licence, 'License number', Icons.badge_outlined),
            const Divider(height: 32),
            const Text('Vehicle', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _field(_vehicleType, 'Vehicle type', Icons.two_wheeler_outlined),
            _field(_vehicleNumber, 'Vehicle number', Icons.confirmation_number_outlined),
            const Divider(height: 32),
            const Text('Payout details', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _field(_bankName, 'Account holder name', Icons.account_balance_outlined),
            _field(_bankNumber, 'Account number', Icons.numbers),
            _field(_ifsc, 'IFSC', Icons.code),
            _field(_upi, 'UPI ID', Icons.qr_code),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }
}
