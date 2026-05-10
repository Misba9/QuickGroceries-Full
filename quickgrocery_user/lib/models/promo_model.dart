import 'package:cloud_firestore/cloud_firestore.dart';

/// Promotional media slot rendered on the Categories discovery page.
///
/// Backed by the `promos` Firestore collection. Designed to be admin-driven:
/// the admin can change `mediaType` between `image | video | lottie | gif`
/// without code changes, control the redirect target, and toggle visibility
/// via [isActive]. Fields default safely so partially-populated documents
/// still render.
class PromoModel {
  const PromoModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mediaType,
    required this.mediaUrl,
    required this.thumbnail,
    required this.ctaLabel,
    required this.redirectType,
    required this.redirectId,
    required this.gradientStart,
    required this.gradientEnd,
    required this.priority,
    required this.isActive,
  });

  final String id;
  final String title;
  final String subtitle;

  /// `'image' | 'video' | 'lottie' | 'gif'`. Anything else falls back to image.
  final String mediaType;
  final String mediaUrl;

  /// Optional thumbnail used while a video/lottie loads.
  final String thumbnail;

  final String ctaLabel;

  /// `'category' | 'product' | 'url' | 'none'`.
  final String redirectType;
  final String redirectId;

  /// Hex (`#RRGGBB`) gradient — drawn behind/around the media when no
  /// matching image is provided.
  final String gradientStart;
  final String gradientEnd;

  final int priority;
  final bool isActive;

  bool get isVideo => mediaType.toLowerCase() == 'video';
  bool get isLottie => mediaType.toLowerCase() == 'lottie';
  bool get isGif =>
      mediaType.toLowerCase() == 'gif' ||
      mediaUrl.toLowerCase().endsWith('.gif');
  bool get isImage => !isVideo && !isLottie && !isGif;
  bool get hasRedirect =>
      redirectType.isNotEmpty &&
      redirectType.toLowerCase() != 'none' &&
      redirectId.isNotEmpty;

  factory PromoModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return PromoModel(
      id: (data['id'] ?? docId).toString(),
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      mediaType: (data['mediaType'] ?? data['type'] ?? 'image').toString(),
      mediaUrl: (data['mediaUrl'] ?? data['url'] ?? data['video'] ?? data['image'] ?? '').toString(),
      thumbnail: (data['thumbnail'] ?? data['image'] ?? '').toString(),
      ctaLabel: (data['ctaLabel'] ?? '').toString(),
      redirectType: (data['redirectType'] ?? 'none').toString(),
      redirectId: (data['redirectId'] ?? '').toString(),
      gradientStart: (data['gradientStart'] ?? '').toString(),
      gradientEnd: (data['gradientEnd'] ?? '').toString(),
      priority: _asInt(data['priority']),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'mediaType': mediaType,
        'mediaUrl': mediaUrl,
        'thumbnail': thumbnail,
        'ctaLabel': ctaLabel,
        'redirectType': redirectType,
        'redirectId': redirectId,
        'gradientStart': gradientStart,
        'gradientEnd': gradientEnd,
        'priority': priority,
        'isActive': isActive,
      };
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

/// Discoverable Firestore reference helper for tests / admin tooling.
CollectionReference<Map<String, dynamic>> promosCollectionRef(
  FirebaseFirestore firestore,
) {
  return firestore.collection('promos');
}
