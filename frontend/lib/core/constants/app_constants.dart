import 'package:flutter/foundation.dart' show kIsWeb;

/// DineQR Constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'DineQR';
  static const String appTagline = 'Scan • Order • Enjoy';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Chrome (web) uses localhost, real phone uses your computer's IP
  static const String _host = '10.5.244.24';
  static const int _port = 8001;

  static String get baseUrl =>
      kIsWeb ? 'http://localhost:$_port/api' : 'http://$_host:$_port/api';

  static String get wsUrl =>
      kIsWeb ? 'ws://localhost:$_port/ws' : 'ws://$_host:$_port/ws';

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
  static const String currency = 'USD';
  static const String currencySymbol = '\$';

  // Payment
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';

  // Stripe
  static const String stripePublishableKey =
      'pk_test_51SYtbCAAbfECi3qV283FG7a0LQ9HKzLe8OOwf4xVIp0DIdrebEnjc3OAay5G0ixVkl6TLu3KY7i3s45KgPfPB1yw002NHNoYcp';
}
