import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';
import 'package:quick_grocery_delivery/constants/primary_button.dart';
import 'package:quick_grocery_delivery/core/auth/partner_auth_api.dart';
import 'package:quick_grocery_delivery/features/login/forgot_password/forgot_password_reset_screen.dart';
import 'package:quick_grocery_delivery/widgets/keyboard_safe_body.dart';

class ForgotPasswordVerifyScreen extends StatefulWidget {
  const ForgotPasswordVerifyScreen({super.key, required this.email});

  final String email;

  @override
  State<ForgotPasswordVerifyScreen> createState() =>
      _ForgotPasswordVerifyScreenState();
}

class _ForgotPasswordVerifyScreenState extends State<ForgotPasswordVerifyScreen> {
  final _api = PartnerAuthApi();
  final List<TextEditingController> _digits =
      List.generate(6, (_) => TextEditingController());
  bool _loading = false;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  String get _otp => _digits.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.verifyResetOtp(widget.email, _otp);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordResetScreen(email: widget.email),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0) return;
    setState(() => _loading = true);
    try {
      await _api.requestPasswordReset(widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent')),
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Verify OTP')),
      body: KeyboardSafeBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Code sent to ${widget.email}'),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44,
                  child: TextField(
                    controller: _digits[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: GlobalVariables.lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              height: size.height,
              width: size.width,
              title: 'Verify',
              isLoading: _loading,
              onTap: _verify,
            ),
            TextButton(
              onPressed: _resendSeconds > 0 || _loading ? null : _resend,
              child: Text(
                _resendSeconds > 0
                    ? 'Resend in ${_resendSeconds}s'
                    : 'Resend OTP',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
