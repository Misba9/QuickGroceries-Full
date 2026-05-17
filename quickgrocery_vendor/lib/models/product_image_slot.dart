import 'dart:io';

/// One product image — either a local file pending upload or a remote URL.
class ProductImageSlot {
  ProductImageSlot({
    required this.key,
    this.localFile,
    this.remoteUrl,
  }) : assert(localFile != null || (remoteUrl != null && remoteUrl.isNotEmpty));

  final String key;
  final File? localFile;
  final String? remoteUrl;

  bool get isLocal => localFile != null;
  bool get isRemote => remoteUrl != null && remoteUrl!.isNotEmpty;

  ProductImageSlot copyWith({File? localFile, String? remoteUrl}) {
    return ProductImageSlot(
      key: key,
      localFile: localFile ?? this.localFile,
      remoteUrl: remoteUrl ?? this.remoteUrl,
    );
  }

  static List<ProductImageSlot> fromUrls(List<String> urls) {
    return urls
        .where((u) => u.trim().isNotEmpty)
        .map(
          (u) => ProductImageSlot(
            key: u,
            remoteUrl: u,
          ),
        )
        .toList();
  }
}
