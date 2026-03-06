import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminDashboardProvider),
        color: AppColors.gold,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: AppColors.background, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Admin',
                      style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.w700, fontSize: 20)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22),
                  onPressed: () => ref.invalidate(adminDashboardProvider),
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 22),
                  onPressed: () => context.go('/login'),
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 4),
              ],
            ),

            // Body
            analyticsAsync.when(
              data: (data) {
                if (data == null) {
                  return const SliverFillRemaining(
                    child: Center(
                        child: Text('Failed to load analytics',
                            style: TextStyle(color: AppColors.textHint))),
                  );
                }

                final today = data['today'] ?? {};
                final weekly = data['weekly'] ?? {};
                final popular = data['popular_items'] as List? ?? [];

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Greeting
                      Text(
                        'Dashboard',
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ).animate().fadeIn().slideX(begin: -0.03),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your restaurant operations',
                        style: GoogleFonts.poppins(
                            color: AppColors.textSecondary, fontSize: 13),
                      ).animate().fadeIn(delay: 80.ms),

                      const SizedBox(height: 24),

                      // Stats
                      _buildStatsGrid(today, data['total_tables'] ?? 15),

                      const SizedBox(height: 28),

                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildActionGrid(context),

                      const SizedBox(height: 28),

                      // Performance
                      Text(
                        'Performance',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSummaryCards(weekly, popular),
                    ]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.gold)),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                    child: Text('Error: $e',
                        style: const TextStyle(color: AppColors.error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<dynamic, dynamic> today, int totalTables) {
    final revenue = today['revenue'] ?? 0;
    final stats = [
      _Stat('Today Revenue', '${revenue.toStringAsFixed(0)} ${AppConstants.currency}',
          Icons.monetization_on_rounded, AppColors.gold),
      _Stat('Today Orders', '${today['orders'] ?? 0}',
          Icons.receipt_long_rounded, AppColors.success),
      _Stat('Active Tables', '${today['active_tables'] ?? 0}/$totalTables',
          Icons.table_restaurant, AppColors.info),
      _Stat('Pending', '${today['pending_orders'] ?? 0}',
          Icons.pending_actions_rounded, AppColors.pending),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final stat = entry.value;
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: stat.color.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: stat.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(stat.icon, color: stat.color, size: 20),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        stat.value,
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stat.label,
                      style: GoogleFonts.poppins(
                          color: AppColors.textHint, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ).animate(delay: (80 * index).ms).fadeIn().scale(
                  begin: const Offset(0.96, 0.96)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _Action('Menu Items', Icons.restaurant_menu_rounded, AppColors.gold,
          () => context.push('/admin/menu')),
      _Action('Categories', Icons.category_rounded, AppColors.info,
          () => context.push('/admin/categories')),
      _Action('Tables & QR', Icons.qr_code_rounded, AppColors.success,
          () => context.push('/admin/tables')),
      _Action('Kitchen', Icons.soup_kitchen_rounded, AppColors.cooking,
          () => context.push('/kitchen')),
      _Action('Cashier', Icons.point_of_sale_rounded, AppColors.pending,
          () => context.push('/cashier')),
      _Action('Orders', Icons.receipt_rounded, AppColors.goldLight,
          () => context.push('/kitchen')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return GestureDetector(
              onTap: action.onTap,
              child: SizedBox(
                width: cardWidth,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.surfaceLight.withOpacity(0.6)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: action.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child:
                              Icon(action.icon, color: action.color, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            action.label,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate(delay: (60 * index).ms)
                .fadeIn()
                .slideY(begin: 0.08);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCards(
      Map<dynamic, dynamic> weekly, List<dynamic> popular) {
    final topItem =
        popular.isNotEmpty ? popular[0]['menu_item__name'] ?? 'N/A' : 'N/A';
    final topCount = popular.isNotEmpty ? popular[0]['total_ordered'] ?? 0 : 0;
    final weeklyRevenue = weekly['revenue'] ?? 0;

    return Column(
      children: [
        _summaryRow('Most Ordered', '$topItem', '$topCount orders',
            Icons.trending_up_rounded, AppColors.gold),
        const SizedBox(height: 10),
        _summaryRow(
            'Weekly Revenue',
            '${weeklyRevenue is num ? weeklyRevenue.toStringAsFixed(0) : weeklyRevenue} ${AppConstants.currency}',
            'Last 7 days',
            Icons.monetization_on_rounded,
            AppColors.success),
      ],
    );
  }

  Widget _summaryRow(
      String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
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
                Text(title,
                    style: GoogleFonts.poppins(
                        color: AppColors.textHint, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(subtitle,
                style: GoogleFonts.poppins(
                    color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
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
