import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/account/account_deletion_exception.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/widgets/pinput_sms_retriever.dart';
import 'package:quickgrocery/core/loading/loading.dart';

/// Phone OTP reauthentication required before [User.delete] after
/// `requires-recent-login`.
///
/// Returns `true` when [User.reauthenticateWithCredential] succeeds.
Future<bool> showAccountDeletionReauthSheet(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final phone = user?.phoneNumber;
  if (user == null || phone == null || phone.isEmpty) {
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useRootNavigator: true,
    backgroundColor: AppSurface.of(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AccountDeletionReauthSheet(phoneNumber: phone),
  );
  return result == true;
}

class _AccountDeletionReauthSheet extends StatefulWidget {
  const _AccountDeletionReauthSheet({required this.phoneNumber});

  final String phoneNumber;

  @override
  State<_AccountDeletionReauthSheet> createState() =>
      _AccountDeletionReauthSheetState();
}

class _AccountDeletionReauthSheetState
    extends State<_AccountDeletionReauthSheet> {
  static const _otpLength = 6;
  static const _resendSeconds = 30;

  final _pinController = TextEditingController();
  final _pinFocus = FocusNode();
  late final PinputSmsRetriever _smsRetriever;

  String _verificationId = '';
  int? _resendToken;
  bool _sending = false;
  bool _verifying = false;
  bool _codeSent = false;
  bool _invalidOtp = false;
  String? _error;
  Timer? _resendTimer;
  int _resendCountdown = _resendSeconds;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _smsRetriever = PinputSmsRetriever();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendOtp();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    unawaited(_smsRetriever.dispose());
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = _resendSeconds;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCountdown <= 1) {
        t.cancel();
        setState(() {
          _resendCountdown = 0;
          _canResend = true;
        });
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _invalidOtp = false;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        forceResendingToken: resend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _reauthenticate(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = e.message ?? e.code;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _sending = false;
            _codeSent = true;
          });
          _startResendCountdown();
          _pinFocus.requestFocus();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          if (_verificationId.isEmpty) {
            setState(() => _verificationId = verificationId);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _verifyPin(String pin) async {
    if (pin.length != _otpLength || _verifying) return;
    if (_verificationId.isEmpty) {
      setState(() => _error = 'OTP session expired. Request a new code.');
      return;
    }

    setState(() {
      _verifying = true;
      _invalidOtp = false;
      _error = null;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: pin,
    );
    await _reauthenticate(credential);
  }

  Future<void> _reauthenticate(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    try {
      await user.reauthenticateWithCredential(credential);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final invalid = e.code == 'invalid-verification-code' ||
          e.code == 'invalid-verification-id' ||
          e.code == 'session-expired';
      setState(() {
        _verifying = false;
        _sending = false;
        _invalidOtp = invalid;
        _error = invalid ? null : (e.message ?? e.code);
      });
      if (invalid) {
        _pinController.clear();
        _pinFocus.requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _sending = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    final defaultPin = PinTheme(
      width: 48,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: KeyboardSafeBody(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
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
                Text(
                  l10n.delete_account_reauth_title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.delete_account_reauth_message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.phoneNumber,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
                const SizedBox(height: 20),
                if (_sending && !_codeSent)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: AppLoading.micro),
                  )
                else ...[
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Pinput(
                      length: _otpLength,
                      controller: _pinController,
                      focusNode: _pinFocus,
                      smsRetriever: _smsRetriever,
                      defaultPinTheme: defaultPin,
                      focusedPinTheme: defaultPin.copyWith(
                        decoration: defaultPin.decoration!.copyWith(
                          border: Border.all(color: AppColor.primary, width: 2),
                        ),
                      ),
                      errorPinTheme: defaultPin.copyWith(
                        decoration: defaultPin.decoration!.copyWith(
                          border: Border.all(color: Colors.red),
                        ),
                      ),
                      forceErrorState: _invalidOtp,
                      enabled: !_verifying,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onCompleted: _verifyPin,
                    ),
                  ),
                  if (_invalidOtp) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Invalid OTP. Try again.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_verifying)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: AppLoading.micro),
                    )
                  else
                    Row(
                      children: [
                        TextButton(
                          onPressed: _canResend && !_sending
                              ? () => _sendOtp(resend: true)
                              : null,
                          child: Text(
                            _canResend
                                ? l10n.delete_account_reauth_send_otp
                                : 'Resend in ${_resendCountdown}s',
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps [AccountDeletionException] to a localized user message.
String accountDeletionErrorMessage(
  BuildContext context,
  Object error,
) {
  final l10n = context.l10n;
  if (error is AccountDeletionException) {
    switch (error.kind) {
      case AccountDeletionErrorKind.network:
        return l10n.delete_account_network_error;
      case AccountDeletionErrorKind.permissionDenied:
        return l10n.delete_account_permission_error;
      case AccountDeletionErrorKind.cancelled:
        return l10n.delete_account_failed;
      case AccountDeletionErrorKind.requiresRecentLogin:
        return l10n.delete_account_reauth_message;
      case AccountDeletionErrorKind.notSignedIn:
      case AccountDeletionErrorKind.authFailed:
      case AccountDeletionErrorKind.dataFailed:
      case AccountDeletionErrorKind.unknown:
        return l10n.delete_account_failed;
    }
  }
  return l10n.delete_account_failed;
}
