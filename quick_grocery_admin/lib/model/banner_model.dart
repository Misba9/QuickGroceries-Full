class BannerModel {
  final String image;
  final String video;
  final String type; // 'image' or 'video'
  final String id;
  final String createddate;

  BannerModel({
    required this.image,
    required this.video,
    required this.type,
    required this.id,
    required this.createddate,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return BannerModel(
      id: data['id'] ?? "",
      image: data['image'] ?? "",
      video: data['video'] ?? "",
      type: data['type'] ?? 'image',
      createddate: data['created_date'].toString(),
    );
  }

  String get mediaUrl => type == 'video' ? video : image;
  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
}
