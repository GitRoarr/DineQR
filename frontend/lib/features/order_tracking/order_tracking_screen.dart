import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart' as models;

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final List<_StatusStep> _steps = [
    _StatusStep(
      status: 'pending',
      title: 'Order Received',
      subtitle: 'Your order is being reviewed',
      icon: Icons.receipt_long_rounded,
      color: AppColors.pending,
    ),
    _StatusStep(
      status: 'cooking',
      title: 'Preparing',
      subtitle: 'Chef is cooking your food',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.cooking,
    ),
    _StatusStep(
      status: 'ready',
      title: 'Ready',
      subtitle: 'Order is ready for pickup',
      icon: Icons.check_circle_rounded,
      color: AppColors.ready,
    ),
    _StatusStep(
      status: 'served',
      title: 'Served',
      subtitle: 'Enjoy your meal!',
      icon: Icons.restaurant_rounded,
      color: AppColors.served,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _listenToSocket();
  }

  void _listenToSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.onOrderStatusUpdate = (data) {
      if (data['order_id'] == widget.orderId) {
        // Invalidate to refresh the order details
        ref.invalidate(orderProvider(widget.orderId));
      }
    };
  }

  int _getStepIndex(String status) {
    if (status == 'cancelled') return 0;
    return _steps.indexWhere((s) => s.status == status);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order Tracking', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(orderProvider(widget.orderId)),
          ),
          TextButton.icon(
            onPressed: () => context.go('/scan'),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Home'),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));
          
          final currentIndex = _getStepIndex(order.status);
          final currentStep = _steps[currentIndex.clamp(0, _steps.length - 1)];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildStatusHeader(order, currentStep),
                const SizedBox(height: 40),
                _buildProgressSteps(currentIndex),
                const SizedBox(height: 40),
                _buildOrderDetails(order),
                const SizedBox(height: 32),
                if (order.status == 'served')
                  GoldButton(
                    text: 'Order Again',
                    icon: Icons.restart_alt_rounded,
                    onPressed: () {
                      final tableId = ref.read(currentTableProvider);
                      context.go('/menu?table=$tableId');
                    },
                  ).animate().fadeIn(),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _notifyWaiter(),
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Call Waiter'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _notifyWaiter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Waiter has been notified!'),
        backgroundColor: AppColors.surfaceLight,
      ),
    );
  }

  Widget _buildStatusHeader(models.Order order, _StatusStep step) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: step.color.withOpacity(0.3), width: 3),
          ),
          child: Icon(step.icon, size: 48, color: step.color),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(),
        const SizedBox(height: 20),
        Text(
          order.status == 'cancelled' ? 'Order Cancelled' : step.title,
          style: GoogleFonts.playfairDisplay(
            color: order.status == 'cancelled' ? AppColors.error : step.color,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Text(
          order.status == 'cancelled' ? 'We apologize for the inconvenience' : step.subtitle,
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildProgressSteps(int currentIndex) {
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? step.color.withOpacity(0.2) : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: isCompleted ? step.color : AppColors.textHint.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(isCompleted ? Icons.check : step.icon, color: isCompleted ? step.color : AppColors.textHint, size: 16),
                ),
                if (index < _steps.length - 1)
                  Container(width: 2, height: 36, color: isCompleted ? step.color.withOpacity(0.4) : AppColors.surfaceLight),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: GoogleFonts.poppins(
                        color: isCurrent ? step.color : (isCompleted ? AppColors.textPrimary : AppColors.textHint),
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      step.subtitle,
                      style: GoogleFonts.poppins(color: isCompleted ? AppColors.textSecondary : AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate(delay: (150 * index).ms).fadeIn().slideX(begin: 0.1);
      }).toList(),
    );
  }

  Widget _buildOrderDetails(models.Order order) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Items', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('#${order.id}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
            ],
          ),
          const Divider(height: 24, color: AppColors.surfaceLight),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('${item.quantity}x', style: GoogleFonts.poppins(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(child: Text(item.itemName, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14))),
                Text('${(item.itemPrice * item.quantity).toStringAsFixed(0)} ${AppConstants.currency}', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          )),
          const Divider(height: 24, color: AppColors.surfaceLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
              Text('${order.total.toStringAsFixed(0)} ${AppConstants.currency}', style: GoogleFonts.poppins(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}

class _StatusStep {
  final String status;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StatusStep({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
