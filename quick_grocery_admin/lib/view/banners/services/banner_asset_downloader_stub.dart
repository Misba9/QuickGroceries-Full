import 'package:http/http.dart' as http;
import 'package:quick_grocery_admin/model/banner_model.dart';

/// Non-web platforms: not implemented in admin (use web build).
Future<void> downloadBannerAsset(BannerModel banner) async {
  throw BannerDownloadException(
    'Banner download is available in the web admin panel.',
  );
}

/// Desktop / mobile fallback: fetches asset bytes (caller may save externally).
Future<List<int>> downloadBannerBytes(BannerModel banner) async {
  final url = _resolveUrl(banner);
  if (url == null) {
    throw BannerDownloadException('No media URL available for this banner');
  }
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw BannerDownloadException('Download failed (${response.statusCode})');
  }
  return response.bodyBytes;
}

String? _resolveUrl(BannerModel banner) {
  if (banner.isVideo && banner.video.isNotEmpty) return banner.video;
  if (banner.image.isNotEmpty) return banner.image;
  if (banner.thumbnailUrl.isNotEmpty) return banner.thumbnailUrl;
  return null;
}

String bannerDownloadFilename(BannerModel banner) {
  final slug = banner.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = slug.isEmpty ? 'banner_${banner.id}' : '${slug}_${banner.id}';
  final ext = banner.isVideo ? 'mp4' : 'jpg';
  return '$base.$ext';
}

class BannerDownloadException implements Exception {
  BannerDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}
