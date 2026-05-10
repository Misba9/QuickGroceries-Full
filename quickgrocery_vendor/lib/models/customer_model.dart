class CustomerModel {
  final String image;
  final String name;
  final String email;
  final String phoneNumber;
  final String id;
  final String createdDate;
  bool isBlocked;

  CustomerModel(
      {required this.image,
      required this.name,
      required this.email,
      required this.id,
      required this.phoneNumber,
      required this.isBlocked,
      required this.createdDate});

  factory CustomerModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CustomerModel(
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        phoneNumber: data['phone'] ?? '',
        image: data['profile_image'] ?? '',
        id: data['uid'] ?? "",
        isBlocked: data['is_blocked'] ?? false,
        createdDate: data['created_date'] ?? "");
  }
}
