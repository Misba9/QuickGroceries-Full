class PasswordResetResult {
  const PasswordResetResult({
    required this.message,
    this.useOtpFlow = false,
  });

  final String message;
  final bool useOtpFlow;
}
