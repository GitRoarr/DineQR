import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/socket_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;
  bool _orderPlaced = false;

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    final cart = ref.read(cartProvider);
    final tableId = ref.read(currentTableProvider) ?? 1;
    final total = ref.read(cartTotalProvider);

    final orderData = {
      'table': tableId,
      'total': total * 1.1, // with service charge
      'items': cart.map((e) => e.toJson()).toList(),
    };

    // Send to API
    final api = ref.read(apiServiceProvider);
    final order = await api.createOrder(orderData);

    // Also emit via socket for real-time kitchen notification
    final socket = ref.read(socketServiceProvider);
    socket.emitNewOrder(orderData);

    // Clear cart
    ref.read(cartProvider.notifier).clearCart();

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
    });

    // Navigate to tracking after animation
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final orderId = order?.id ?? 0;
      context.go('/tracking/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    if (_orderPlaced) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table info
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.table_restaurant, color: AppColors.gold),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${ref.watch(currentTableProvider) ?? 1}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Your order will be served here',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Order summary
            const Text(
              'Order Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...cart.asMap().entries.map((entry) {
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.menuItem.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${item.totalPrice.toStringAsFixed(0)} ${AppConstants.currency}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (60 * entry.key).ms).fadeIn().slideX(begin: 0.05);
            }),

            const SizedBox(height: 16),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  _priceRow('Subtotal', total),
                  const SizedBox(height: 8),
                  _priceRow('Service charge (10%)', total * 0.1),
                  const Divider(height: 24, color: AppColors.surfaceLight),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${(total * 1.1).toStringAsFixed(0)} ${AppConstants.currency}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(),

            const SizedBox(height: 32),

            // Confirm button
            GoldButton(
              text: 'Confirm Order',
              icon: Icons.check_circle_rounded,
              isLoading: _isProcessing,
              onPressed: _placeOrder,
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Note
            Center(
              child: Text(
                'Your order will be sent to the kitchen immediately',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(
          '${amount.toStringAsFixed(0)} ${AppConstants.currency}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 70,
              ),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            const Text(
              'Order Placed!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 8),

            const Text(
              'Your order has been sent to the kitchen',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold.withOpacity(0.5)),
              ),
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
