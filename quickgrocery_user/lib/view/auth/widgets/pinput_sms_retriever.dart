import 'dart:async';

import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Bridges [sms_autofill] into [Pinput]'s [SmsRetriever] API.
class PinputSmsRetriever implements SmsRetriever {
  PinputSmsRetriever({this.codeRegex = r'\d{6}'});

  final String codeRegex;
  final SmsAutoFill _sms = SmsAutoFill();
  StreamSubscription<String>? _sub;

  @override
  bool get listenForMultipleSms => false;

  @override
  Future<String?> getSmsCode() async {
    final completer = Completer<String?>();
    await _sms.listenForCode(smsCodeRegexPattern: codeRegex);
    _sub = _sms.code.listen((raw) {
      final digits = RegExp(r'\d').allMatches(raw).map((m) => m.group(0)!).join();
      if (digits.length == 6 && !completer.isCompleted) {
        completer.complete(digits);
        _sub?.cancel();
      }
    });
    return completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => null,
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _sms.unregisterListener();
  }
}
