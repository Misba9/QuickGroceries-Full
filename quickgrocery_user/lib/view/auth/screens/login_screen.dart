import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_session_provider.dart';
import 'package:quickgrocery/core/widgets/keyboard_safe_body.dart';
import 'package:quickgrocery/view/auth/screens/firebase_diagnostic_screen.dart';
import 'package:quickgrocery/view/auth/services/auth_provider.dart';
import 'package:quickgrocery/view/auth/widgets/primary_button.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      legacy_provider.Provider.of<AuthService>(context, listen: false)
          .ensurePhoneAuthGuardReady();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      legacy_provider.Provider.of<AuthService>(context, listen: false)
          .ensurePhoneAuthGuardReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = legacy_provider.Provider.of<AuthService>(context);
    final cooldown = provider.otpCooldownSeconds;
    final continueEnabled = provider.canRequestOtp;
    final continueLabel = cooldown > 0
        ? context.l10n.resend_otp_in(cooldown)
        : context.l10n.continueAction;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: KeyboardSafeBody(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              AppSpacing.h20,
              GestureDetector(
                onLongPress: kDebugMode
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FirebaseDiagnosticScreen(),
                          ),
                        );
                      }
                    : null,
                child: Image.asset('assets/images/logo.png'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('+91'),
                    const SizedBox(height: 30, child: VerticalDivider()),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.phone,
                        controller: provider.mobileController,
                        enabled: !provider.isLoading,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: context.l10n.phone_number,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.h10,
              if (provider.phoneAuthError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (provider.phoneAuthErrorInfo?.title.isNotEmpty ==
                          true) ...[
                        Text(
                          provider.phoneAuthErrorInfo!.title,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.phoneAuthErrorInfo!.message,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ] else
                        Text(
                          provider.phoneAuthError!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                          ),
                        ),
                      if (provider.phoneAuthNeedsRetry) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: provider.isLoading
                                ? null
                                : () {
                                    provider.clearPhoneAuthError();
                                    provider.verifyPhoneNumber(context);
                                  },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.h10,
              ],
              AppSpacing.h20,
              PrimaryButton(
                isLoading: provider.isLoading,
                label: continueLabel,
                onTap: !continueEnabled
                    ? null
                    : () {
                        provider.clearPhoneAuthError();
                        if (provider.mobileController.text
                                .replaceAll(RegExp(r'\D'), '')
                                .length <
                            10) {
                          AppSnackBar.error(
                            context.l10n.please_enter_valid_phone,
                            context: context,
                          );
                        } else {
                          provider.verifyPhoneNumber(context);
                        }
                      },
              ),
              AppSpacing.h15,
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                            return;
                          }
                          await ref.read(guestSessionProvider.notifier).enable();
                          GuestAuthCoordinator.notifyGuestModeEntered();
                        },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    context.l10n.skipForNow,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
