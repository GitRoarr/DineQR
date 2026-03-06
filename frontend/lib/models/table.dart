/// Table model
class RestaurantTable {
  final int id;
  final int number;
  final String name;
  final int capacity;
  final bool isActive;
  final String qrCode;
  final int activeOrdersCount;

  RestaurantTable({
    required this.id,
    required this.number,
    this.name = '',
    this.capacity = 4,
    this.isActive = true,
    this.qrCode = '',
    this.activeOrdersCount = 0,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] ?? 0,
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 4,
      isActive: json['is_active'] ?? true,
      qrCode: json['qr_code'] ?? '',
      activeOrdersCount: json['active_orders_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'capacity': capacity,
      'is_active': isActive,
    };
  }
}
