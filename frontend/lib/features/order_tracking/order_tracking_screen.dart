import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../providers/app_providers.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  String _currentStatus = 'pending';

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
        setState(() {
          _currentStatus = data['status'] ?? _currentStatus;
        });
      }
    };
  }

  int get _currentStepIndex {
    return _steps.indexWhere((s) => s.status == _currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/scan'),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Big status icon
            _buildStatusHeader(),

            const SizedBox(height: 40),

            // Progress steps
            _buildProgressSteps(),

            const SizedBox(height: 40),

            // Estimated time
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.timer_rounded, color: AppColors.gold),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Time',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                      Text(
                        '15-25 minutes',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 16),

            // Table info
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                      const Text(
                        'Table',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                      Text(
                        'Table ${ref.watch(currentTableProvider) ?? '?'}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            // New order button
            if (_currentStatus == 'served')
              GoldButton(
                text: 'Order Again',
                icon: Icons.restart_alt_rounded,
                onPressed: () {
                  final tableId = ref.read(currentTableProvider);
                  context.go('/menu?table=$tableId');
                },
              ).animate().fadeIn(delay: 400.ms),

            // Call waiter button
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Waiter has been notified!'),
                    backgroundColor: AppColors.surfaceLight,
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Call Waiter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final step = _steps[_currentStepIndex.clamp(0, _steps.length - 1)];
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: step.color.withOpacity(0.3), width: 3),
          ),
          child: Icon(step.icon, size: 56, color: step.color),
        )
            .animate()
            .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut)
            .fadeIn(),

        const SizedBox(height: 20),

        Text(
          step.title,
          style: TextStyle(
            color: step.color,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 4),

        Text(
          step.subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildProgressSteps() {
    return Column(
      children: _steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= _currentStepIndex;
        final isCurrent = index == _currentStepIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted ? step.color.withOpacity(0.2) : AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? step.color : AppColors.textHint.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : step.icon,
                    color: isCompleted ? step.color : AppColors.textHint,
                    size: 18,
                  ),
                ),
                if (index < _steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? step.color.withOpacity(0.4) : AppColors.surfaceLight,
                  ),
              ],
            ),

            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        color: isCurrent ? step.color : (isCompleted ? AppColors.textPrimary : AppColors.textHint),
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        color: isCompleted ? AppColors.textSecondary : AppColors.textHint,
                        fontSize: 12,
                      ),
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
