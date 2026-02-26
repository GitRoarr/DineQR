/// Order model
class Order {
  final int id;
  final int tableId;
  final int tableNumber;
  final String status;
  final double total;
  final List<OrderItemData> items;
  final String createdAt;

  Order({
    required this.id,
    required this.tableId,
    this.tableNumber = 0,
    required this.status,
    required this.total,
    required this.items,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      tableId: json['table'] ?? 0,
      tableNumber: json['table_number'] ?? 0,
      status: json['status'] ?? 'pending',
      total: (json['total'] ?? 0).toDouble(),
      items: (json['items'] as List?)
              ?.map((e) => OrderItemData.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'table': tableId,
      'status': status,
      'total': total,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

/// Individual order item
class OrderItemData {
  final int id;
  final int itemId;
  final String itemName;
  final double itemPrice;
  final int quantity;
  final String notes;

  OrderItemData({
    required this.id,
    required this.itemId,
    this.itemName = '',
    this.itemPrice = 0,
    required this.quantity,
    this.notes = '',
  });

  factory OrderItemData.fromJson(Map<String, dynamic> json) {
    return OrderItemData(
      id: json['id'] ?? 0,
      itemId: json['item'] ?? json['item_id'] ?? 0,
      itemName: json['item_name'] ?? '',
      itemPrice: (json['item_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': itemId,
      'quantity': quantity,
      'notes': notes,
    };
  }
}
