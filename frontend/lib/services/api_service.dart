import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/table.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add JWT interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Try refreshing token
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry request
              final token = await _storage.read(key: AppConstants.tokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── AUTH ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String identifier, String password) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'identifier': identifier,
        'password': password,
      });
      final data = response.data;
      await _storage.write(key: AppConstants.tokenKey, value: data['access']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refresh']);
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refresh = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refresh == null) return false;
      final response = await _dio.post('/auth/refresh/', data: {'refresh': refresh});
      await _storage.write(key: AppConstants.tokenKey, value: response.data['access']);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  // ─── CATEGORIES ────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/menu/categories/');
      return (response.data as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── MENU ITEMS ────────────────────────────────────────────

  Future<List<MenuItem>> getMenuItems({int? categoryId, bool showAll = false}) async {
    try {
      String url = '/menu/items/';
      final params = <String, String>{};
      if (categoryId != null) {
        params['category'] = categoryId.toString();
      }
      if (showAll) {
        params['all'] = 'true';
      }
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }
      final response = await _dio.get(url);
      return (response.data as List).map((e) => MenuItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<MenuItem?> getMenuItem(int id) async {
    try {
      final response = await _dio.get('/menu/items/$id/');
      return MenuItem.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  // ─── ORDERS ────────────────────────────────────────────────

  Future<Order?> createOrder(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/orders/create/', data: data);
      return Order.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<RestaurantTable?> getTableByNumber(int number) async {
    try {
      final response = await _dio.get('/orders/tables/number/$number/');
      return RestaurantTable.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Order>> getTableOrders(int tableId) async {
    try {
      final response = await _dio.get('/orders/table/$tableId/');
      return (response.data as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Order?> getOrder(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/');
      return Order.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      await _dio.patch('/orders/$orderId/status/', data: {'status': status});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── KITCHEN ───────────────────────────────────────────────

  Future<List<Order>> getKitchenOrders() async {
    try {
      final response = await _dio.get('/orders/kitchen/');
      return (response.data as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── CASHIER ───────────────────────────────────────────────

  Future<List<Order>> getCashierOrders({String paymentStatus = 'unpaid'}) async {
    try {
      final response = await _dio.get('/orders/cashier/', queryParameters: {
        'payment_status': paymentStatus,
      });
      return (response.data as List).map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> markOrderPaid(int orderId, {String paymentMethod = 'cash'}) async {
    try {
      await _dio.post('/orders/$orderId/mark-paid/', data: {
        'payment_method': paymentMethod,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── STRIPE / PAYMENTS ──────────────────────────────────────

  /// Get the Stripe publishable key from the backend
  Future<String?> getStripePublishableKey() async {
    try {
      final response = await _dio.get('/orders/stripe-config/');
      return response.data['publishable_key'];
    } catch (e) {
      return null;
    }
  }

  /// Create a Stripe PaymentIntent for an order and return the client_secret
  Future<String?> createPaymentIntent(int orderId) async {
    try {
      final response = await _dio.post('/orders/$orderId/create-payment-intent/');
      return response.data['client_secret'];
    } catch (e) {
      return null;
    }
  }

  // ─── TABLES ──────────────────────────────────────────────────

  Future<List<RestaurantTable>> getTables() async {
    try {
      final response = await _dio.get('/orders/tables/');
      return (response.data as List).map((e) => RestaurantTable.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> createTable(Map<String, dynamic> data) async {
    try {
      await _dio.post('/orders/tables/', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTable(int id) async {
    try {
      await _dio.delete('/orders/tables/$id/');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> generateQrCode(int tableId) async {
    try {
      await _dio.post('/orders/tables/$tableId/generate-qr/');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── CATEGORIES (ADMIN) ─────────────────────────────────────

  Future<bool> deleteCategory(int id) async {
    try {
      await _dio.delete('/menu/categories/$id/');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/menu/categories/$id/', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── ADMIN ─────────────────────────────────────────────────

  Future<bool> createMenuItem(Map<String, dynamic> data) async {
    try {
      await _dio.post('/menu/items/', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMenuItem(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/menu/items/$id/', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMenuItem(int id) async {
    try {
      await _dio.delete('/menu/items/$id/');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      await _dio.post('/menu/categories/', data: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final response = await _dio.get('/orders/dashboard/');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
