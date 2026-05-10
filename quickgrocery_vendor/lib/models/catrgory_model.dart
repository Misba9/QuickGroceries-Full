class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String order;
  final String creatdDate;
  final String? mainCategory; // For subcategories

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.order,
    required this.creatdDate,
    this.mainCategory,
  });

  factory CategoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CategoryModel(
        id: data['id'] ?? "",
        name: data['name'] ?? "",
        image: data['image'] ?? "",
        order: data['order'].toString(),
        creatdDate: data['createdAt'].toString(),
        mainCategory: data['main_category']);
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String orderValue = '0';
    if (json['order'] is int) {
      orderValue = json['order'].toString();
    } else if (json['order'] is String) {
      orderValue = json['order'];
    }
    
    String dateValue = "";
    if (json['createdAt'] != null) {
      dateValue = json['createdAt'].toString();
    }
    
    return CategoryModel(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      image: json['image'] ?? "",
      order: orderValue,
      creatdDate: dateValue,
      mainCategory: json['main_category'],
    );
  }
}
