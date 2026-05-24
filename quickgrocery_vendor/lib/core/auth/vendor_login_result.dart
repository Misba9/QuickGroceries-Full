import '../../models/vendor_model.dart';

class VendorLoginResult {
  const VendorLoginResult.success(this.vendor)
      : errorMessage = null;

  const VendorLoginResult.failure(this.errorMessage) : vendor = null;

  final VendorModel? vendor;
  final String? errorMessage;

  bool get isSuccess => vendor != null;
}
