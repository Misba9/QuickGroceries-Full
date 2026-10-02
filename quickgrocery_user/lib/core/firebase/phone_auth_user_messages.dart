import 'package:firebase_auth/firebase_auth.dart';

/// User-facing phone-auth error (title + body). Prefer [display] in banners.
class PhoneAuthUserMessage {
  const PhoneAuthUserMessage({
    required this.title,
    required this.message,
    this.code,
  });

  final String title;
  final String message;
  final String? code;

  /// Combined text for existing single-string UI banners.
  String get display {
    if (title.isEmpty) return message;
    if (message.isEmpty) return title;
    return '$title\n\n$message';
  }
}

/// Maps [FirebaseAuthException.code] → friendly copy for login / OTP.
abstract final class PhoneAuthUserMessages {
  static PhoneAuthUserMessage fromException(FirebaseAuthException e) {
    return fromCode(e.code, fallbackMessage: e.message);
  }

  static PhoneAuthUserMessage fromCode(
    String code, {
    String? fallbackMessage,
  }) {
    switch (code) {
      case 'too-many-requests':
        return const PhoneAuthUserMessage(
          title: 'Too Many Attempts',
          message:
              "You've requested OTP multiple times.\n"
              'Please wait a few minutes before trying again.',
          code: 'too-many-requests',
        );
      case 'quota-exceeded':
        return const PhoneAuthUserMessage(
          title: 'SMS Limit Reached',
          message:
              'We cannot send more verification codes right now.\n'
              'Please try again later.',
          code: 'quota-exceeded',
        );
      case 'invalid-phone-number':
        return const PhoneAuthUserMessage(
          title: 'Invalid Phone Number',
          message:
              'Please enter a valid 10-digit Indian mobile number.',
          code: 'invalid-phone-number',
        );
      case 'captcha-check-failed':
        return const PhoneAuthUserMessage(
          title: 'Verification Failed',
          message:
              'Security check did not complete. Close any browser tab, '
              'then try again.',
          code: 'captcha-check-failed',
        );
      case 'network-request-failed':
        return const PhoneAuthUserMessage(
          title: 'No Internet',
          message:
              'Check your connection and tap Retry.',
          code: 'network-request-failed',
        );
      case 'session-expired':
        return const PhoneAuthUserMessage(
          title: 'Code Expired',
          message:
              'This OTP is no longer valid. Request a new code.',
          code: 'session-expired',
        );
      case 'invalid-verification-code':
        return const PhoneAuthUserMessage(
          title: 'Incorrect OTP',
          message: 'The code you entered is wrong. Please try again.',
          code: 'invalid-verification-code',
        );
      case 'invalid-verification-id':
        return const PhoneAuthUserMessage(
          title: 'Session Expired',
          message: 'Request a new OTP and try again.',
          code: 'invalid-verification-id',
        );
      case 'credential-already-in-use':
        return const PhoneAuthUserMessage(
          title: 'Number Already Linked',
          message:
              'This phone number is already linked to another account.',
          code: 'credential-already-in-use',
        );
      case 'app-not-authorized':
        return const PhoneAuthUserMessage(
          title: 'App Not Authorized',
          message:
              'This build is not authorized for phone login. '
              'Please update the app or contact support.',
          code: 'app-not-authorized',
        );
      case 'operation-not-allowed':
        return const PhoneAuthUserMessage(
          title: 'Phone Login Disabled',
          message:
              'Phone sign-in is temporarily unavailable. '
              'Please try again later.',
          code: 'operation-not-allowed',
        );
      case 'missing-client-identifier':
        return const PhoneAuthUserMessage(
          title: 'Phone Login Unavailable',
          message:
              'This app build is missing a valid app identifier. '
              'Please update the app or contact support.',
          code: 'missing-client-identifier',
        );
      case 'invalid-app-credential':
      case 'invalid-cert-hash':
        return const PhoneAuthUserMessage(
          title: 'App Verification Failed',
          message:
              'Could not verify this app install. '
              'Update the app from the store and try again.',
          code: 'invalid-app-credential',
        );
      case 'user-disabled':
        return const PhoneAuthUserMessage(
          title: 'Account Disabled',
          message: 'This account has been disabled. Contact support.',
          code: 'user-disabled',
        );
      case 'internal-error':
        return const PhoneAuthUserMessage(
          title: 'Something Went Wrong',
          message:
              'We could not complete phone verification. '
              'Please wait a moment and try again.',
          code: 'internal-error',
        );
      default:
        final detail = (fallbackMessage ?? '').trim();
        return PhoneAuthUserMessage(
          title: 'Sign-In Failed',
          message: detail.isEmpty
              ? 'Please try again. If this continues, contact support.'
              : detail,
          code: code,
        );
    }
  }

  static const PhoneAuthUserMessage invalidLocalPhone = PhoneAuthUserMessage(
    title: 'Invalid Phone Number',
    message: 'Please enter a valid 10-digit Indian mobile number.',
    code: 'invalid-phone-number',
  );

  static const PhoneAuthUserMessage noInternet = PhoneAuthUserMessage(
    title: 'No Internet',
    message: 'Check your connection and tap Retry.',
    code: 'network-request-failed',
  );

  static const PhoneAuthUserMessage cooldownActive = PhoneAuthUserMessage(
    title: 'Please Wait',
    message: 'You can request another OTP when the timer finishes.',
    code: 'cooldown',
  );

  static const PhoneAuthUserMessage otpSessionExpired = PhoneAuthUserMessage(
    title: 'Session Expired',
    message: 'OTP session expired. Go back and request a new code.',
    code: 'session-expired',
  );

  static const PhoneAuthUserMessage timedOut = PhoneAuthUserMessage(
    title: 'Timed Out',
    message:
        'Phone verification took too long. Check your network and try again.',
    code: 'timeout',
  );
}
