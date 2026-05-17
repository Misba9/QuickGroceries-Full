import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/partner_security/partner_account_client.dart';

/// Bottom sheet: reset password, send OTP email, force logout, enable/disable, force change.
class PartnerSecuritySheet extends StatefulWidget {
  const PartnerSecuritySheet({
    super.key,
    required this.role,
    required this.partnerId,
    required this.email,
    required this.isActive,
  });

  /// `vendor` or `delivery`
  final String role;
  final String partnerId;
  final String email;
  final bool isActive;

  static Future<void> show(
    BuildContext context, {
    required String role,
    required String partnerId,
    required String email,
    required bool isActive,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PartnerSecuritySheet(
        role: role,
        partnerId: partnerId,
        email: email,
        isActive: isActive,
      ),
    );
  }

  @override
  State<PartnerSecuritySheet> createState() => _PartnerSecuritySheetState();
}

class _PartnerSecuritySheetState extends State<PartnerSecuritySheet> {
  final _client = PartnerAccountClient();
  bool _busy = false;
  late bool _enabled = widget.isActive;

  Future<void> _run(Future<String> Function() task) async {
    setState(() => _busy = true);
    try {
      final msg = await task();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manualReset() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set temporary password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New password',
            helperText: 'Min 8 chars, 1 uppercase, 1 number',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || controller.text.isEmpty) return;
    await _run(() => _client.resetPasswordManual(
          role: widget.role,
          partnerId: widget.partnerId,
          newPassword: controller.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.role == 'vendor' ? 'Vendor' : 'Delivery partner';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$label security',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(widget.email, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Reset password manually'),
            subtitle: const Text('Sets temp password; user must change on next login'),
            onTap: _busy ? null : _manualReset,
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Send password reset email'),
            subtitle: const Text('Sends 6-digit OTP to registered email'),
            onTap: _busy
                ? null
                : () => _run(() => _client.sendPasswordResetEmail(
                      role: widget.role,
                      partnerId: widget.partnerId,
                    )),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Force logout all devices'),
            onTap: _busy
                ? null
                : () => _run(() => _client.forceLogout(
                      role: widget.role,
                      partnerId: widget.partnerId,
                    )),
          ),
          SwitchListTile(
            secondary: Icon(
              _enabled ? Icons.check_circle : Icons.block,
              color: _enabled ? Colors.green : Colors.red,
            ),
            title: const Text('Account enabled'),
            value: _enabled,
            activeColor: AppColor.primary,
            onChanged: _busy
                ? null
                : (v) async {
                    setState(() => _enabled = v);
                    await _run(() => _client.setEnabled(
                          role: widget.role,
                          partnerId: widget.partnerId,
                          enabled: v,
                        ));
                  },
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Require password change on next login'),
            onTap: _busy
                ? null
                : () => _run(() => _client.setForcePasswordChange(
                      role: widget.role,
                      partnerId: widget.partnerId,
                      force: true,
                    )),
          ),
        ],
      ),
    );
  }
}
