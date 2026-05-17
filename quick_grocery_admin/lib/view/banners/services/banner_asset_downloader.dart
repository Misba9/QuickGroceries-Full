import 'package:quick_grocery_admin/model/banner_model.dart';

export 'banner_asset_downloader_stub.dart'
    show BannerDownloadException, bannerDownloadFilename;

import 'banner_asset_downloader_stub.dart'
    if (dart.library.html) 'banner_asset_downloader_web.dart' as platform;

/// Downloads banner image/video to the user's device (web: save dialog).
Future<void> downloadBannerAsset(BannerModel banner) =>
    platform.downloadBannerAsset(banner);
