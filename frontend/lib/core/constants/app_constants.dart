/// DineQR Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'DineQR';
  static const String appTagline = 'Scan • Order • Enjoy';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  static const String wsUrl = 'ws://10.0.2.2:8000/ws';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tableKey = 'current_table';
  static const String roleKey = 'user_role';
  static const String languageKey = 'app_language';

  // Order Status
  static const String statusPending = 'pending';
  static const String statusCooking = 'cooking';
  static const String statusReady = 'ready';
  static const String statusServed = 'served';
  static const String statusCancelled = 'cancelled';

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleKitchen = 'kitchen';
  static const String roleAdmin = 'admin';

  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 800);

  // Currency
  static const String currency = 'ETB';
}
