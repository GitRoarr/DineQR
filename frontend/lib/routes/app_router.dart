import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/qr_scan/qr_scan_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/menu/item_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/order_tracking/order_tracking_screen.dart';
import '../features/kitchen/kitchen_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/menu_management_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const QRScanScreen(),
    ),
    GoRoute(
      path: '/menu',
      name: 'menu',
      builder: (context, state) {
        final tableId = state.uri.queryParameters['table'];
        return MenuScreen(tableId: int.tryParse(tableId ?? ''));
      },
    ),
    GoRoute(
      path: '/item/:id',
      name: 'item-detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ItemDetailScreen(itemId: id);
      },
    ),
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/tracking/:orderId',
      name: 'tracking',
      builder: (context, state) {
        final orderId = int.parse(state.pathParameters['orderId']!);
        return OrderTrackingScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/kitchen',
      name: 'kitchen',
      builder: (context, state) => const KitchenScreen(),
    ),
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/menu',
      name: 'admin-menu',
      builder: (context, state) => const MenuManagementScreen(),
    ),
  ],
);
