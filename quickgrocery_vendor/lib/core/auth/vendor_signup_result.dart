class VendorSignupResult {
  const VendorSignupResult.success({
    required this.message,
    this.needsApproval = true,
  }) : errorMessage = null;

  const VendorSignupResult.failure(this.errorMessage)
      : message = null,
        needsApproval = false;

  final String? message;
  final String? errorMessage;
  final bool needsApproval;

  bool get isSuccess => errorMessage == null;
}
