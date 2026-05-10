class DeliveryPersonModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String createdDate;
  final String email;
  final String password;
  final String address;
  final String image;
  final String licenceNumber;
  bool isActive;

  DeliveryPersonModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.createdDate,
    required this.email,
    required this.password,
    required this.address,
    required this.image,
    required this.licenceNumber,
    required this.isActive,
  });

  factory DeliveryPersonModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return DeliveryPersonModel(
      id: id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      phone: data['phone'] ?? '',
      createdDate: data['createdDate'] ?? DateTime.now().toString(),
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      address: data['address'] ?? '',
      image: data['image'] ?? '',
      licenceNumber: data['licence_number'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "id": id,
      "first_name": firstName,
      "last_name": lastName,
      "phone": phone,
      "createdDate": createdDate,
      "email": email,
      "password": password,
      "address": address,
      "image": image,
      "licence_number": licenceNumber,
      "is_active": isActive,
    };
  }
}
