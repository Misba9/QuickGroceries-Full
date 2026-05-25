import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/vendor/services/vendor_service.dart';

/// Admin tools: restore auth, reset password, force re-sync.
class VendorAuthRecoverySheet extends StatefulWidget {
  const VendorAuthRecoverySheet({super.key, required this.vendor});

  final VendorModel vendor;

  static Future<void> show(BuildContext context, VendorModel vendor) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: VendorAuthRecoverySheet(vendor: vendor),
      ),
    );
  }

  @override
  State<VendorAuthRecoverySheet> createState() =>
      _VendorAuthRecoverySheetState();
}

class _VendorAuthRecoverySheetState extends State<VendorAuthRecoverySheet> {
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    final svc = context.watch<VendorService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            v.shopName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            v.email,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text('Status: ${v.displayStatus}'),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(
                  v.needsFirebaseAuthSync ? 'Auth: Not synced' : 'Auth: Synced',
                ),
                backgroundColor: v.needsFirebaseAuthSync
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password (min 8 characters)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: svc.isLoading
                ? null
                : () async {
                    if (_passwordCtrl.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 8 characters.'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    await context.read<VendorService>().restoreVendorAuth(
                          context,
                          vendorDocId: v.id,
                          shopName: v.shopName,
                          password: _passwordCtrl.text,
                        );
                  },
            icon: svc.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.healing_outlined),
            label: const Text('Restore Firebase Auth'),
            style: FilledButton.styleFrom(backgroundColor: AppColor.primary),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: svc.isLoading
                ? null
                : () async {
                    if (_passwordCtrl.text.length < 8) return;
                    Navigator.pop(context);
                    await context.read<VendorService>().migrateVendorAuth(
                          context,
                          vendorDocId: v.id,
                          password: _passwordCtrl.text,
                        );
                  },
            icon: const Icon(Icons.sync),
            label: const Text('Force re-sync Firebase Auth'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: svc.isLoading
                ? null
                : () async {
                    if (_passwordCtrl.text.length < 8) return;
                    Navigator.pop(context);
                    await context.read<VendorService>().resetVendorPassword(
                          context,
                          email: v.email,
                          password: _passwordCtrl.text,
                        );
                  },
            icon: const Icon(Icons.lock_reset),
            label: const Text('Reset password only'),
          ),
          OutlinedButton.icon(
            onPressed: svc.isLoading
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            'Vendor login\nEmail: ${v.email}\nPassword: (use the password you set above)\nApp: Quick Grocery Vendor',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Login details copied (email: ${v.email}). Share the password separately.',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Resend login credentials'),
          ),
          const SizedBox(height: 12),
          Text(
            'After restore, the vendor logs in with this email and password in the vendor app.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
