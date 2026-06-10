import 'package:quickgrocery/core/firebase/firebase_phone_auth_logger.dart';

/// Structured phone-auth lifecycle logs (logcat: `PhoneAuth`).
abstract final class PhoneAuthLog {
  static void appStarted() => _log('app_started');
  static void continueTapped() => _log('continue_tapped');
  static void verifyPhoneCalled() => _log('verifyPhoneNumber_called');
  static void verificationCompleted() => _log('verificationCompleted');
  static void verificationFailed(String code) =>
      _log('verificationFailed code=$code');
  static void codeSent() => _log('codeSent');
  static void codeAutoRetrievalTimeout() => _log('codeAutoRetrievalTimeout');
  static void otpScreenOpened() => _log('otp_screen_opened');
  static void otpEntered() => _log('otp_entered');
  static void credentialCreated() => _log('credential_created');
  static void signInSuccess({required String uid}) =>
      _log('signInWithCredential_success uid=$uid');
  static void sessionStored() => _log('session_stored');
  static void navigateHome() => _log('navigate_home');
  static void duplicateTapIgnored(String where) =>
      _log('duplicate_tap_ignored where=$where');

  static void _log(String event) {
    FirebasePhoneAuthLogger.info('[flow] $event');
  }
}
