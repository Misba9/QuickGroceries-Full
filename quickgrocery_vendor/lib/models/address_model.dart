class AddressModel {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String area;
  final String type;
  final String createdAt;
  final String lastEdited;
  final String userId;

  AddressModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.area,
    required this.type,
    required this.createdAt,
    required this.lastEdited,
    required this.userId,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json["id"],
        name: json["name"],
        mobile: json["mobile"],
        address: json["address"],
        area: json["area"],
        type: json["type"],
        createdAt: json["createdAt"],
        lastEdited: json["lastEdited"],
        userId: json["user_id"],
      );

  factory AddressModel.fromFirestore(Map<String, dynamic> json, String id) {
    return AddressModel(
      id: json["id"],
      name: json["name"],
      mobile: json["mobile"],
      address: json["address"],
      area: json["area"],
      type: json["type"],
      createdAt: json["createdAt"].toString(),
      lastEdited: json["lastEdited"].toString(),
      userId: json["user_id"],
    );
  }
}
