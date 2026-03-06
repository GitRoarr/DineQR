import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/order.dart' as models;
import '../../providers/app_providers.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Cooking', 'Ready'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _listenToSocket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _listenToSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.onNewOrder = (data) {
      ref.invalidate(kitchenOrdersProvider);
      _showNewOrderNotification();
    };
  }

  void _showNewOrderNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('New order received!',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final success =
        await ref.read(apiServiceProvider).updateOrderStatus(orderId, newStatus);
    if (success) {
      ref.invalidate(kitchenOrdersProvider);
      ref.read(socketServiceProvider).emitStatusUpdate(orderId, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                  child: const Icon(Icons.restaurant_rounded,
                      color: AppColors.background, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Kitchen',
                    style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w700, fontSize: 20)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                onPressed: () => ref.invalidate(kitchenOrdersProvider),
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 22),
                onPressed: () => context.go('/login'),
                tooltip: 'Logout',
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.gold,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: _tabs
                    .map((t) => Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_tabIcon(t), size: 16),
                              const SizedBox(width: 6),
                              Text(t),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
        body: ordersAsync.when(
          data: (orders) {
            final pendingCount =
                orders.where((o) => o.status == 'pending').length;
            final cookingCount =
                orders.where((o) => o.status == 'cooking').length;
            final readyCount =
                orders.where((o) => o.status == 'ready').length;

            return Column(
              children: [
                // Stats row
                _buildStatsRow(pendingCount, cookingCount, readyCount),

                // Tab body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(orders),
                      _buildOrderList(orders
                          .where((o) => o.status == 'pending')
                          .toList()),
                      _buildOrderList(orders
                          .where((o) => o.status == 'cooking')
                          .toList()),
                      _buildOrderList(orders
                          .where((o) => o.status == 'ready')
                          .toList()),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(
              child: Text('Error: $e',
                  style: const TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }

  IconData _tabIcon(String tab) {
    switch (tab) {
      case 'Pending':
        return Icons.access_time_rounded;
      case 'Cooking':
        return Icons.local_fire_department_rounded;
      case 'Ready':
        return Icons.check_circle_rounded;
      default:
        return Icons.list_rounded;
    }
  }

  Widget _buildStatsRow(int pending, int cooking, int ready) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildStatChip(
              '$pending', 'Pending', AppColors.pending, Icons.access_time),
          const SizedBox(width: 10),
          _buildStatChip('$cooking', 'Cooking', AppColors.cooking,
              Icons.local_fire_department),
          const SizedBox(width: 10),
          _buildStatChip(
              '$ready', 'Ready', AppColors.ready, Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: color.withOpacity(0.7), fontSize: 10),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(List<models.Order> orders) {
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'All caught up!',
        subtitle: 'No orders in this category',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(kitchenOrdersProvider),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index], index),
      ),
    );
  }

  Widget _buildOrderCard(models.Order order, int index) {
    final statusColor = _statusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: order.status == 'pending'
              ? AppColors.pending.withOpacity(0.35)
              : AppColors.surfaceLight.withOpacity(0.6),
          width: order.status == 'pending' ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with table + status
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'T${order.tableNumber}',
                    style: GoogleFonts.poppins(
                      color: AppColors.background,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber.isNotEmpty ? order.orderNumber : order.id}',
                        style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order.createdAt.isNotEmpty)
                        Text(
                          _formatTime(order.createdAt),
                          style: GoogleFonts.poppins(
                              color: AppColors.textHint, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Center(
                                child: Text(
                                  '${item.quantity}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (item.notes.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.error.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '📝 ${item.notes}',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.error
                                                .withOpacity(0.9),
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: _buildActionButtons(order),
          ),
        ],
      ),
    ).animate(delay: (60 * index).ms).fadeIn().slideY(begin: 0.04);
  }

  Widget _buildActionButtons(models.Order order) {
    if (order.status == 'served' || order.status == 'cancelled') {
      return const SizedBox.shrink();
    }

    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () => _updateStatus(order.id, 'cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded, size: 16),
                        SizedBox(width: 4),
                        Text('Reject',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _updateStatus(order.id, 'cooking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_fire_department_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Start Cooking',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'cooking':
        return _buildSingleAction(
          'Mark Ready',
          Icons.check_circle_rounded,
          AppColors.success,
          () => _updateStatus(order.id, 'ready'),
        );
      case 'ready':
        return _buildSingleAction(
          'Mark Served',
          Icons.restaurant_rounded,
          AppColors.served,
          () => _updateStatus(order.id, 'served'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSingleAction(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.pending;
      case 'cooking':
        return AppColors.cooking;
      case 'ready':
        return AppColors.ready;
      case 'served':
        return AppColors.served;
      default:
        return AppColors.textHint;
    }
  }

  String _formatTime(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
