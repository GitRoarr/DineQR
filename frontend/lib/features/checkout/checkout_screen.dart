import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/app_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessing = false;
  bool _orderPlaced = false;
  String _paymentMethod = AppConstants.paymentCash; // 'cash' or 'card'

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    final cart = ref.read(cartProvider);
    final tableId = ref.read(currentTableIdProvider) ?? 1;
    final api = ref.read(apiServiceProvider);

    // 1) Create order on backend
    final orderData = {
      'table_id': tableId,
      'payment_method': _paymentMethod,
      'items': cart.map((e) => e.toJson()).toList(),
    };

    final order = await api.createOrder(orderData);
    if (order == null) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('Failed to create order. Please try again.');
      }
      return;
    }

    // 2) If card payment, process Stripe
    if (_paymentMethod == AppConstants.paymentCard) {
      final paid = await _processStripePayment(order.id);
      if (!paid) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError('Card payment failed. You can pay at the counter.');
        }
        // Still navigate to tracking — order exists but unpaid
        _navigateToTracking(order.id);
        return;
      }
    }

    // 3) Emit socket event for real-time kitchen notification
    final socket = ref.read(socketServiceProvider);
    socket.emitNewOrder(orderData);

    // 4) Clear cart & show success
    ref.read(cartProvider.notifier).clearCart();

    setState(() {
      _isProcessing = false;
      _orderPlaced = true;
    });

    // Navigate to tracking after animation
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _navigateToTracking(order.id);
    }
  }

  Future<bool> _processStripePayment(int orderId) async {
    try {
      final api = ref.read(apiServiceProvider);

      // 1) Create PaymentIntent on backend
      final clientSecret = await api.createPaymentIntent(orderId);
      if (clientSecret == null) return false;

      // 2) Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppConstants.appName,
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              background: AppColors.surface,
              primary: AppColors.gold,
              componentBackground: AppColors.card,
              componentText: AppColors.textPrimary,
              secondaryText: AppColors.textSecondary,
              placeholderText: AppColors.textHint,
              icon: AppColors.gold,
            ),
            shapes: PaymentSheetShape(
              borderRadius: 16,
              borderWidth: 1,
            ),
          ),
        ),
      );

      // 3) Present the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // 4) If we reach here, payment succeeded — mark paid on backend
      await api.markOrderPaid(orderId, paymentMethod: 'card');
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }

  void _navigateToTracking(int orderId) {
    if (mounted) context.go('/tracking/$orderId');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                    child: const Icon(Icons.table_restaurant,
                        color: AppColors.gold),
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
                        style:
                            TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Order summary
            Text(
              'Order Summary',
              style: GoogleFonts.poppins(
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
              )
                  .animate(delay: (60 * entry.key).ms)
                  .fadeIn()
                  .slideX(begin: 0.05);
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

            const SizedBox(height: 28),

            // ─── PAYMENT METHOD ────────────────────────────────
            Text(
              'Payment Method',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    label: 'Cash',
                    subtitle: 'Pay at counter',
                    icon: Icons.money_rounded,
                    value: AppConstants.paymentCash,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentOption(
                    label: 'Card',
                    subtitle: 'Visa / Mastercard',
                    icon: Icons.credit_card_rounded,
                    value: AppConstants.paymentCard,
                  ),
                ),
              ],
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 28),

            // Confirm button
            GoldButton(
              text: _paymentMethod == AppConstants.paymentCard
                  ? 'Pay & Place Order'
                  : 'Place Order',
              icon: _paymentMethod == AppConstants.paymentCard
                  ? Icons.credit_card_rounded
                  : Icons.check_circle_rounded,
              isLoading: _isProcessing,
              onPressed: _placeOrder,
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 16),

            // Note
            Center(
              child: Text(
                _paymentMethod == AppConstants.paymentCard
                    ? 'You will be redirected to a secure payment form'
                    : 'Your order will be sent to the kitchen immediately',
                style: GoogleFonts.poppins(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String label,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : AppColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withOpacity(0.15)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isSelected ? AppColors.gold : AppColors.textHint,
                  size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.gold : AppColors.textHint,
              size: 22,
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
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
        Text(
          '${amount.toStringAsFixed(0)} ${AppConstants.currency}',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 14),
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
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Text(
              _paymentMethod == AppConstants.paymentCard
                  ? 'Payment Successful!'
                  : 'Order Placed!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 8),

            Text(
              _paymentMethod == AppConstants.paymentCard
                  ? 'Your card has been charged. Order sent to kitchen.'
                  : 'Your order has been sent to the kitchen',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.gold.withOpacity(0.5)),
              ),
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }
}
