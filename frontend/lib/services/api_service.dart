import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';

/// API Service — handles all HTTP communication with Django backend
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

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login/', data: {
        'username': username,
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

  Future<List<MenuItem>> getMenuItems({int? categoryId}) async {
    try {
      String url = '/menu/items/';
      if (categoryId != null) {
        url += '?category=$categoryId';
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
      await _dio.put('/orders/$orderId/status/', data: {'status': status});
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
      final response = await _dio.get('/admin/analytics/');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
