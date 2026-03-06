import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(AppConstants.splashDuration);
    if (mounted) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF1A1A0E),
              AppColors.background,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.25),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/dineqr_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 32),

              // App Name
              const Text(
                'DineQR',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Scan • Order • Enjoy',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w300,
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 60),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.gold.withOpacity(0.5),
                  ),
                ),
              )
                  .animate(delay: 900.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
