// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:http/http.dart' as http;
import 'package:quick_grocery_admin/model/banner_model.dart';
import 'package:quick_grocery_admin/view/banners/services/banner_asset_downloader_stub.dart'
    show BannerDownloadException, bannerDownloadFilename;

/// Triggers a browser file download for the banner image or video.
Future<void> downloadBannerAsset(BannerModel banner) async {
  final url = _resolveUrl(banner);
  if (url == null) {
    throw BannerDownloadException('No media URL available for this banner');
  }

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw BannerDownloadException('Download failed (${response.statusCode})');
  }

  final bytes = response.bodyBytes;
  final mime = banner.isVideo ? 'video/mp4' : 'image/jpeg';
  final blob = html.Blob([bytes], mime);
  final blobUrl = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: blobUrl)
    ..download = bannerDownloadFilename(banner)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(blobUrl);
}

String? _resolveUrl(BannerModel banner) {
  if (banner.isVideo && banner.video.isNotEmpty) return banner.video;
  if (banner.image.isNotEmpty) return banner.image;
  if (banner.thumbnailUrl.isNotEmpty) return banner.thumbnailUrl;
  return null;
}
