import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/pinput_sms_retriever.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class OtpAuthScreen extends StatefulWidget {
  static String route = 'otpScreen';
  const OtpAuthScreen({super.key});

  @override
  State<OtpAuthScreen> createState() => _OtpAuthScreenState();
}

class _OtpAuthScreenState extends State<OtpAuthScreen>
    with SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  static const int _resendSeconds = 30;

  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocus = FocusNode();
  late final AnimationController _shakeController;
  late final PinputSmsRetriever _smsRetriever;

  Timer? _resendTimer;
  int _resendCountdown = _resendSeconds;
  bool _canResend = false;
  bool _localVerifying = false;
  bool _invalidOtp = false;

  @override
  void initState() {
    super.initState();
    _smsRetriever = PinputSmsRetriever();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _startResendCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
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

  Future<void> _verifyIfComplete(String pin) async {
    if (pin.length != _otpLength || _localVerifying) return;
    final auth = context.read<AuthService>();
    if (auth.isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _localVerifying = true;
      _invalidOtp = false;
    });

    final ok = await auth.signInWithOTP(pin, context);

    if (!mounted) return;

    if (ok) {
      setState(() => _localVerifying = false);
      return;
    }

    setState(() {
      _localVerifying = false;
      _invalidOtp = true;
    });
    _pinController.clear();
    _shakeController.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    final auth = context.read<AuthService>();
    await auth.resendOtp(context);
    if (mounted) {
      _pinController.clear();
      setState(() => _invalidOtp = false);
      _startResendCountdown();
      _pinFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _shakeController.dispose();
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final verifying = _localVerifying || auth.isLoading;
    final theme = Theme.of(context);
    final primary = AppColor.primary;
    final size = MediaQuery.sizeOf(context);
    final fieldW = (size.width - 48).clamp(220.0, 400.0) / _otpLength - 6;

    final defaultPin = PinTheme(
      width: fieldW.clamp(40.0, 52.0),
      height: 52,
      textStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ) ??
          const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
    );

    final focusedPin = defaultPin.copyDecorationWith(
      border: Border.all(color: primary, width: 2),
      boxShadow: [
        BoxShadow(
          color: primary.withValues(alpha: 0.28),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

    final submittedPin = defaultPin.copyWith(
      decoration: defaultPin.decoration?.copyWith(
        border: Border.all(color: primary.withValues(alpha: 0.5)),
      ),
    );

    final errorPin = defaultPin.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.error, width: 1.5),
    );

    final shakeAnim = TweenSequence<double>([
      for (int i = 0; i < 6; i++)
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: i.isEven ? 10.0 : -10.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -10, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_shakeController);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          fillMinHeight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: verifying ? null : () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.please_type_verification_code,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(context.l10n.to, style: theme.textTheme.bodyLarge),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '+91 ${auth.mobileController.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              AnimatedBuilder(
                animation: shakeAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(shakeAnim.value, 0),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AutofillGroup(
                      child: Pinput(
                        length: _otpLength,
                        controller: _pinController,
                        focusNode: _pinFocus,
                        autofocus: true,
                        enabled: !verifying,
                        smsRetriever: _smsRetriever,
                        defaultPinTheme: defaultPin,
                        focusedPinTheme: focusedPin,
                        submittedPinTheme: submittedPin,
                        errorPinTheme: errorPin,
                        forceErrorState: _invalidOtp,
                        separatorBuilder: (i) => const SizedBox(width: 6),
                        hapticFeedbackType: HapticFeedbackType.lightImpact,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        closeKeyboardWhenCompleted: false,
                        animationCurve: Curves.easeOutCubic,
                        animationDuration: const Duration(milliseconds: 220),
                        pinAnimationType: PinAnimationType.scale,
                        onChanged: (v) {
                          if (_invalidOtp) {
                            setState(() => _invalidOtp = false);
                          }
                        },
                        onCompleted: (pin) => _verifyIfComplete(pin),
                      ),
                    ),
                    if (verifying)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _invalidOtp
                    ? Text(
                        context.l10n.invalid_otp,
                        key: const ValueKey('err'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox(height: 20, key: ValueKey('ok')),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: (_canResend && !verifying) ? _onResend : null,
                child: Text(
                  _canResend
                      ? context.l10n.resend
                      : context.l10n.resend_otp_in(_resendCountdown),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _canResend ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.dont_receive_otp,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
