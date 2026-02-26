/// MenuItem model
class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int categoryId;
  final String categoryName;
  final bool available;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
    this.categoryName = '',
    this.available = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? '',
      categoryId: json['category'] ?? json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      available: json['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': categoryId,
      'available': available,
    };
  }
}
