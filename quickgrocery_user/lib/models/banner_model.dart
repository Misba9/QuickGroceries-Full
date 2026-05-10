import 'package:cloud_firestore/cloud_firestore.dart';

/// BannerModel — extended schema for the dynamic homepage.
///
/// Backward compatible with the legacy schema:
/// `image`, `video`, `type`, `id`, `created_date`.
/// New fields (`redirectType`, `redirectId`, `priority`, `isActive`) default
/// safely so existing documents keep working.
class BannerModel {
  final String id;
  final String image;
  final String video;
  final String type; // 'image' | 'video'
  final String redirectType; // 'category' | 'product' | 'url' | 'none'
  final String redirectId;
  final int priority;
  final bool isActive;
  final String createddate;
  final DateTime? createdAt;

  const BannerModel({
    required this.id,
    required this.image,
    required this.video,
    required this.type,
    required this.redirectType,
    required this.redirectId,
    required this.priority,
    required this.isActive,
    required this.createddate,
    this.createdAt,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    final created = _asDateTime(data['createdAt'] ?? data['created_date']);
    return BannerModel(
      id: (data['id'] ?? id).toString(),
      image: data['image']?.toString() ?? '',
      video: data['video']?.toString() ?? '',
      type: data['type']?.toString() ?? 'image',
      redirectType: data['redirectType']?.toString() ?? 'none',
      redirectId: data['redirectId']?.toString() ?? '',
      priority: _asInt(data['priority']),
      isActive: data['isActive'] as bool? ?? true,
      createddate: (data['created_date'] ?? data['createdAt'] ?? '').toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'video': video,
    'type': type,
    'redirectType': redirectType,
    'redirectId': redirectId,
    'priority': priority,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  BannerModel copyWith({
    String? id,
    String? image,
    String? video,
    String? type,
    String? redirectType,
    String? redirectId,
    int? priority,
    bool? isActive,
    String? createddate,
    DateTime? createdAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      image: image ?? this.image,
      video: video ?? this.video,
      type: type ?? this.type,
      redirectType: redirectType ?? this.redirectType,
      redirectId: redirectId ?? this.redirectId,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createddate: createddate ?? this.createddate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get mediaUrl => type == 'video' ? video : image;
  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
  bool get hasRedirect => redirectType != 'none' && redirectId.isNotEmpty;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
