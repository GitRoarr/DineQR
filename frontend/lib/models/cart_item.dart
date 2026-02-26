import 'menu_item.dart';

/// Cart item model (menu item + quantity + notes)
class CartItem {
  final MenuItem menuItem;
  int quantity;
  String notes;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.notes = '',
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'item': menuItem.id,
      'quantity': quantity,
      'notes': notes,
    };
  }
}
