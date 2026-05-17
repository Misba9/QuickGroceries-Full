import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/model/banner_model.dart';

/// Priority tiers mapped to Firestore `priority` values.
enum BannerPriorityTier { low, medium, high }

extension BannerPriorityTierX on BannerPriorityTier {
  int get value => switch (this) {
        BannerPriorityTier.low => 5,
        BannerPriorityTier.medium => 10,
        BannerPriorityTier.high => 20,
      };

  String get label => switch (this) {
        BannerPriorityTier.low => 'Low',
        BannerPriorityTier.medium => 'Medium',
        BannerPriorityTier.high => 'High',
      };

  static BannerPriorityTier fromPriority(int p) {
    if (p >= 15) return BannerPriorityTier.high;
    if (p >= 8) return BannerPriorityTier.medium;
    return BannerPriorityTier.low;
  }
}

/// Immutable snapshot for live preview widgets.
class BannerPreviewData {
  const BannerPreviewData({
    required this.bannerType,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    this.imageBytes,
    this.imageUrl,
    this.isVideo = false,
    this.showAsPopup = false,
  });

  final String bannerType;
  final String title;
  final String subtitle;
  final String ctaText;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isVideo;
  final bool showAsPopup;
}

/// Filter for existing banners list.
enum BannerListFilter { all, active, inactive, scheduled, image, video }

/// Form field bundle passed into form / preview panels.
class BannerFormControllers {
  BannerFormControllers()
      : title = TextEditingController(),
        subtitle = TextEditingController(),
        cta = TextEditingController(text: 'Shop now'),
        redirectId = TextEditingController(),
        popupSecs = TextEditingController(text: '12');

  final TextEditingController title;
  final TextEditingController subtitle;
  final TextEditingController cta;
  final TextEditingController redirectId;
  final TextEditingController popupSecs;

  String redirectType = 'offers_page';
  bool isActive = true;
  bool showInHome = true;
  bool showInOffers = true;
  bool showAsPopup = false;
  bool autoplay = true;
  bool loop = true;
  bool muted = true;
  BannerPriorityTier priorityTier = BannerPriorityTier.medium;
  DateTime? startsAt;
  DateTime? endsAt;

  String? editingId;
  String existingImageUrl = '';
  String existingVideoUrl = '';
  String existingThumbnailUrl = '';

  void dispose() {
    title.dispose();
    subtitle.dispose();
    cta.dispose();
    redirectId.dispose();
    popupSecs.dispose();
  }

  void reset() {
    title.clear();
    subtitle.clear();
    cta.text = 'Shop now';
    redirectId.clear();
    popupSecs.text = '12';
    redirectType = 'offers_page';
    isActive = true;
    showInHome = true;
    showInOffers = true;
    showAsPopup = false;
    autoplay = true;
    loop = true;
    muted = true;
    priorityTier = BannerPriorityTier.medium;
    startsAt = null;
    endsAt = null;
    editingId = null;
    existingImageUrl = '';
    existingVideoUrl = '';
    existingThumbnailUrl = '';
  }

  void loadFromBanner(BannerModel b, {bool duplicate = false}) {
    title.text = duplicate && b.title.isNotEmpty ? '${b.title} (Copy)' : b.title;
    subtitle.text = b.subtitle;
    cta.text = b.ctaText.isEmpty ? 'Shop now' : b.ctaText;
    redirectType = b.redirectType;
    redirectId.text = b.redirectId;
    isActive = b.isActive;
    showInHome = b.showInHome;
    showInOffers = b.showInOffers;
    showAsPopup = b.showAsPopup;
    autoplay = b.autoplay;
    loop = b.loop;
    muted = b.muted;
    popupSecs.text = b.popupAutoCloseSeconds.toString();
    priorityTier = BannerPriorityTierX.fromPriority(b.priority);
    startsAt = b.startsAt;
    endsAt = b.endsAt;
    existingImageUrl = b.image;
    existingVideoUrl = b.video;
    existingThumbnailUrl = b.thumbnailUrl;
    editingId = duplicate ? null : b.id;
  }

  BannerPreviewData previewData({
    required String bannerType,
    Uint8List? imageBytes,
  }) {
    return BannerPreviewData(
      bannerType: bannerType,
      title: title.text.trim(),
      subtitle: subtitle.text.trim(),
      ctaText: cta.text.trim().isEmpty ? 'Shop now' : cta.text.trim(),
      imageBytes: imageBytes,
      imageUrl: existingImageUrl.isNotEmpty ? existingImageUrl : null,
      isVideo: bannerType == 'video',
      showAsPopup: showAsPopup,
    );
  }
}
