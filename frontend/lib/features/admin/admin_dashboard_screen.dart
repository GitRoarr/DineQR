import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, color: AppColors.background, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Admin Panel'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            const Text(
              'Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn().slideX(begin: -0.05),
            const SizedBox(height: 4),
            const Text(
              'Manage your restaurant',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // Stats grid
            _buildStatsGrid(),

            const SizedBox(height: 28),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionGrid(context),

            const SizedBox(height: 28),

            // Recent orders
            const Text(
              'Today\'s Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      _Stat('Revenue', '12,540 ${AppConstants.currency}', Icons.monetization_on_rounded, AppColors.gold),
      _Stat('Orders', '47', Icons.receipt_long_rounded, AppColors.success),
      _Stat('Active Tables', '8/15', Icons.table_restaurant, AppColors.info),
      _Stat('Pending', '3', Icons.pending_actions_rounded, AppColors.pending),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: stat.color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: stat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(stat.icon, color: stat.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ).animate(delay: (100 * index).ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _Action('Menu Items', Icons.restaurant_menu_rounded, AppColors.gold, () => context.push('/admin/menu')),
      _Action('Categories', Icons.category_rounded, AppColors.info, () {}),
      _Action('Tables & QR', Icons.qr_code_rounded, AppColors.success, () {}),
      _Action('Orders', Icons.receipt_rounded, AppColors.pending, () => context.push('/kitchen')),
      _Action('Analytics', Icons.bar_chart_rounded, AppColors.goldLight, () {}),
      _Action('Staff', Icons.people_rounded, AppColors.served, () {}),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        _summaryRow('Most ordered', 'Classic Burger', '23 orders', Icons.trending_up_rounded, AppColors.gold),
        const SizedBox(height: 8),
        _summaryRow('Peak hour', '12:00 - 1:00 PM', '18 orders', Icons.access_time_rounded, AppColors.info),
        const SizedBox(height: 8),
        _summaryRow('Avg order value', '265 ${AppConstants.currency}', '+12% vs yesterday', Icons.show_chart_rounded, AppColors.success),
      ],
    );
  }

  Widget _summaryRow(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.03);
  }
}

class _Stat {
  final String label, value;
  final IconData icon;
  final Color color;
  _Stat(this.label, this.value, this.icon, this.color);
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _Action(this.label, this.icon, this.color, this.onTap);
}
