/// Table model
class RestaurantTable {
  final int id;
  final int number;
  final String qrCode;

  RestaurantTable({
    required this.id,
    required this.number,
    required this.qrCode,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'] ?? 0,
      number: json['number'] ?? 0,
      qrCode: json['qr_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'qr_code': qrCode,
    };
  }
}
