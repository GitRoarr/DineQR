import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = ref.read(apiServiceProvider);
    final result = await api.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (result != null && mounted) {
      final role = result['role'] ?? 'customer';
      ref.read(userRoleProvider.notifier).state = role;
      ref.read(isAuthenticatedProvider.notifier).state = true;

      if (role == 'kitchen') {
        context.go('/kitchen');
      } else if (role == 'cashier') {
        context.go('/cashier');
      } else if (role == 'admin') {
        context.go('/admin');
      } else {
        context.go('/scan');
      }
    } else {
      setState(() {
        _error = 'Invalid email or password';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo section
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/dineqr_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    const Text(
                      'DineQR',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 4),
                    const Text(
                      'Staff Login',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Username
              const Text(
                'Email or Username',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _identifierController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter email or username',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password
              const Text(
                'Password',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Login button
              GoldButton(
                text: 'Login',
                icon: Icons.login_rounded,
                isLoading: _isLoading,
                onPressed: _login,
              ),

              const SizedBox(height: 24),

              // Customer mode
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/scan'),
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: const Text('Continue as Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
