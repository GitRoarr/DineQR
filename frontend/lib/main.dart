import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Stripe (only on mobile — not supported on web)
  if (!kIsWeb) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
  }

  // Set system UI overlay style for premium dark look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock portrait orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: DineQRApp(),
    ),
  );
}

class DineQRApp extends StatelessWidget {
  const DineQRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DineQR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
