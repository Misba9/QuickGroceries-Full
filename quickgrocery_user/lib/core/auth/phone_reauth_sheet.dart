import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';

/// Phone re-auth for account deletion. Uses [User.reauthenticateWithCredential]
/// so we never create a different session.
class PhoneReauthSheet extends StatefulWidget {
  const PhoneReauthSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: const PhoneReauthSheet(),
      ),
    );
    return result == true;
  }

  @override
  State<PhoneReauthSheet> createState() => _PhoneReauthSheetState();
}

class _PhoneReauthSheetState extends State<PhoneReauthSheet> {
  final _pin = TextEditingController();
  String? _verificationId;
  bool _sending = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = context.l10n.deleteAccountNeedPhone;
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _reauth(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = context.l10n.deleteAccountReauthFailed;
          });
          debugPrint('ACCOUNT_DELETE reauth failed: ${e.code}');
        },
        codeSent: (id, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = id;
            _sending = false;
          });
        },
        codeAutoRetrievalTimeout: (id) {
          if (!mounted) return;
          setState(() => _verificationId = id);
        },
      );
    } catch (e) {
      debugPrint('ACCOUNT_DELETE reauth start: $e');
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = context.l10n.deleteAccountReauthFailed;
      });
    }
  }

  Future<void> _submit() async {
    final id = _verificationId;
    final sms = _pin.text.trim();
    if (id == null || sms.length < 6 || _verifying) return;
    await _reauth(
      PhoneAuthProvider.credential(verificationId: id, smsCode: sms),
    );
  }

  Future<void> _reauth(PhoneAuthCredential credential) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('signed-out');
      }
      await user.reauthenticateWithCredential(credential);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ACCOUNT_DELETE reauth credential: $e');
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = context.l10n.deleteAccountReauthFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.deleteAccountReauthTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteAccountReauthBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_sending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Pinput(
                controller: _pin,
                length: 6,
                autofocus: true,
                enabled: !_verifying,
                onCompleted: (_) => _submit(),
                defaultPinTheme: PinTheme(
                  width: 44,
                  height: 48,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 44,
                  height: 48,
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.delete_account,
              isLoading: _verifying,
              onTap: _sending
                  ? null
                  : () {
                      _submit();
                    },
            ),
            TextButton(
              onPressed: _verifying ? null : () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
