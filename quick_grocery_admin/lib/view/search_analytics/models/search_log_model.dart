import 'package:cloud_firestore/cloud_firestore.dart';

class SearchLogModel {
  const SearchLogModel({
    required this.id,
    required this.query,
    required this.queryNormalized,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.resultCount,
    required this.hasResults,
    required this.source,
    required this.platform,
    required this.appVersion,
    required this.catalogSampleSize,
    required this.topResultIds,
    required this.topResultNames,
    required this.createdAt,
  });

  final String id;
  final String query;
  final String queryNormalized;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final int resultCount;
  final bool hasResults;
  final String source;
  final String platform;
  final String appVersion;
  final int catalogSampleSize;
  final List<String> topResultIds;
  final List<String> topResultNames;
  final DateTime? createdAt;

  factory SearchLogModel.fromDoc(DocumentSnapshot doc) {
    final rawData = doc.data();
    final data = rawData is Map<String, dynamic>
        ? rawData
        : (rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : const <String, dynamic>{});
    return SearchLogModel.fromMap(data, id: doc.id);
  }

  factory SearchLogModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime? createdAt;
    final raw = data['createdAt'] ?? data['clientAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is DateTime) {
      createdAt = raw;
    } else if (raw is String && raw.isNotEmpty) {
      createdAt = DateTime.tryParse(raw);
    }

    List<String> asStringList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    final resultCount = (data['resultCount'] is num)
        ? (data['resultCount'] as num).toInt()
        : int.tryParse('${data['resultCount'] ?? 0}') ?? 0;

    return SearchLogModel(
      id: id ?? (data['id'] ?? '').toString(),
      query: (data['query'] ?? '').toString(),
      queryNormalized: (data['queryNormalized'] ?? data['query'] ?? '')
          .toString()
          .toLowerCase()
          .trim(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      userPhone: (data['userPhone'] ?? '').toString(),
      userEmail: (data['userEmail'] ?? '').toString(),
      resultCount: resultCount,
      hasResults: data['hasResults'] == true || resultCount > 0,
      source: (data['source'] ?? '').toString(),
      platform: (data['platform'] ?? data['fcmPlatform'] ?? '').toString(),
      appVersion: (data['appVersion'] ?? data['app_version'] ?? '').toString(),
      catalogSampleSize: (data['catalogSampleSize'] is num)
          ? (data['catalogSampleSize'] as num).toInt()
          : 0,
      topResultIds: asStringList(data['topResultIds']),
      topResultNames: asStringList(data['topResultNames']),
      createdAt: createdAt,
    );
  }

  String get displayUser {
    if (userName.trim().isNotEmpty) return userName.trim();
    if (userPhone.trim().isNotEmpty) return userPhone.trim();
    if (userEmail.trim().isNotEmpty) return userEmail.trim();
    if (userId.trim().isNotEmpty) return userId.trim();
    return 'Guest';
  }
}

class SearchQueryAggregate {
  SearchQueryAggregate({
    required this.query,
    required this.queryNormalized,
  });

  String query;
  final String queryNormalized;
  int count = 0;
  int zeroResultCount = 0;
  final Set<String> userIds = {};
  DateTime? lastSearchedAt;
  String lastPlatform = '';

  double get zeroResultRate =>
      count == 0 ? 0 : (zeroResultCount / count) * 100;
}
