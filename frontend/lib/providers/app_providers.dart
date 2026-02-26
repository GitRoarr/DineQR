import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

// ─── SERVICES ─────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

// ─── TABLE STATE ──────────────────────────────────────────────

final currentTableProvider = StateProvider<int?>((ref) => null);

// ─── CATEGORIES ───────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getCategories();
});

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

// ─── MENU ITEMS ───────────────────────────────────────────────

final menuItemsProvider = FutureProvider.family<List<MenuItem>, int?>((ref, categoryId) async {
  final api = ref.read(apiServiceProvider);
  return api.getMenuItems(categoryId: categoryId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredMenuItemsProvider = Provider.family<AsyncValue<List<MenuItem>>, int?>((ref, categoryId) {
  final itemsAsync = ref.watch(menuItemsProvider(categoryId));
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return itemsAsync.whenData((items) {
    if (query.isEmpty) return items;
    return items.where((item) =>
      item.name.toLowerCase().contains(query) ||
      item.description.toLowerCase().contains(query)
    ).toList();
  });
});

// ─── CART ─────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(MenuItem item) {
    final index = state.indexWhere((e) => e.menuItem.id == item.id);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        CartItem(menuItem: item, quantity: state[index].quantity + 1, notes: state[index].notes),
        ...state.sublist(index + 1),
      ];
    } else {
      state = [...state, CartItem(menuItem: item)];
    }
  }

  void removeItem(int itemId) {
    state = state.where((e) => e.menuItem.id != itemId).toList();
  }

  void updateQuantity(int itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final index = state.indexWhere((e) => e.menuItem.id == itemId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        CartItem(
          menuItem: state[index].menuItem,
          quantity: quantity,
          notes: state[index].notes,
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  void updateNotes(int itemId, String notes) {
    final index = state.indexWhere((e) => e.menuItem.id == itemId);
    if (index >= 0) {
      state = [
        ...state.sublist(0, index),
        CartItem(
          menuItem: state[index].menuItem,
          quantity: state[index].quantity,
          notes: notes,
        ),
        ...state.sublist(index + 1),
      ];
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalPrice => state.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

// ─── ORDERS ───────────────────────────────────────────────────

final currentOrderProvider = StateProvider<Order?>((ref) => null);

final tableOrdersProvider = FutureProvider.family<List<Order>, int>((ref, tableId) async {
  final api = ref.read(apiServiceProvider);
  return api.getTableOrders(tableId);
});

// ─── KITCHEN ──────────────────────────────────────────────────

final kitchenOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getKitchenOrders();
});

// ─── AUTH ─────────────────────────────────────────────────────

final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
final userRoleProvider = StateProvider<String>((ref) => 'customer');
