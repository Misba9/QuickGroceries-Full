import 'package:cloud_firestore/cloud_firestore.dart';

/// CategoryModel — extended schema for the dynamic homepage.
///
/// Backward compatible with the legacy schema (`name`, `image`, `order`).
/// New fields (`id`, `isActive`, `createdAt`) gracefully default when absent
/// so existing Firestore documents keep working without migration.
class CategoryModel {
  final String id;
  final String name;
  final String image;
  final int order;
  final bool isActive;
  final DateTime? createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
    this.isActive = true,
    this.createdAt,
  });

  /// Legacy factory kept for compatibility with code that already calls
  /// `CategoryModel.fromJson(doc.data())`. When the document id is unknown
  /// (older callers), [id] falls back to an empty string.
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      order: _asInt(json['order']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: _asDateTime(json['createdAt']),
    );
  }

  /// Preferred factory for the new architecture — pulls the document id
  /// directly so we never lose it during serialization.
  factory CategoryModel.fromFirestore(
    Map<String, dynamic> data,
    String docId,
  ) {
    return CategoryModel(
      id: docId,
      name: data['name']?.toString() ?? '',
      image: data['image']?.toString() ?? '',
      order: _asInt(data['order']),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _asDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'order': order,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
  };

  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    int? order,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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
