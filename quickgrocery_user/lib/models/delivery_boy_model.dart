class DeliveryBoyModel {
  final String name;
  final String phoneNumber;
  final String image;
  final String id;

  DeliveryBoyModel({
    required this.name,
    required this.phoneNumber,
    required this.image,
    required this.id,
  });

  factory DeliveryBoyModel.fromFirestore(Map<String, dynamic> data, String id) {
    return DeliveryBoyModel(
      name: data['name'] ?? '',
      phoneNumber: data['phone'] ?? '',
      image: data['image'] ?? '',
      id: data['id'],
    );
  }
}
