import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/order.dart' as models;
import '../../providers/app_providers.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _listenToSocket();
  }

  void _listenToSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.onNewOrder = (data) {
      // Invalidate the provider to fetch new orders from backend
      ref.invalidate(kitchenOrdersProvider);
      _showNewOrderNotification();
    };
  }

  void _showNewOrderNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔥 New Order Received!'),
        backgroundColor: AppColors.gold,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    final success = await ref.read(apiServiceProvider).updateOrderStatus(orderId, newStatus);
    if (success) {
      // Invalidate to refresh the list
      ref.invalidate(kitchenOrdersProvider);
      
      // Emit update via socket
      ref.read(socketServiceProvider).emitStatusUpdate(orderId, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(kitchenOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_rounded, color: AppColors.gold, size: 24),
            const SizedBox(width: 8),
            Text('Kitchen Dashboard', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(kitchenOrdersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          final filteredOrders = _filterOrders(orders);
          final pendingCount = orders.where((o) => o.status == 'pending').length;
          final cookingCount = orders.where((o) => o.status == 'cooking').length;

          return Column(
            children: [
              _buildFilterRow(),
              _buildStatsRow(pendingCount, cookingCount, orders.where((o) => o.status == 'ready').length),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'All caught up!',
                        subtitle: 'No orders in this category',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(filteredOrders[index], index);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  List<models.Order> _filterOrders(List<models.Order> orders) {
    if (_selectedFilter == 'all') return orders;
    return orders.where((o) => o.status == _selectedFilter).toList();
  }

  Widget _buildFilterRow() {
    final filters = [
      ('all', 'All', Icons.list_rounded),
      ('pending', 'Pending', Icons.access_time_rounded),
      ('cooking', 'Cooking', Icons.local_fire_department_rounded),
      ('ready', 'Ready', Icons.check_circle_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    f.$3,
                    size: 16,
                    color: isSelected ? AppColors.background : AppColors.textHint,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f.$2,
                    style: GoogleFonts.poppins(
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsRow(int pending, int cooking, int ready) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Pending', '$pending', AppColors.pending, Icons.access_time),
          const SizedBox(width: 12),
          _buildStatCard('Cooking', '$cooking', AppColors.cooking, Icons.local_fire_department),
          const SizedBox(width: 12),
          _buildStatCard('Ready', '$ready', AppColors.ready, Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.poppins(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: GoogleFonts.poppins(color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(models.Order order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.status == 'pending'
              ? AppColors.pending.withOpacity(0.4)
              : AppColors.surfaceLight,
          width: order.status == 'pending' ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Table ${order.tableNumber}',
                        style: GoogleFonts.poppins(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '#${order.id}',
                      style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
                StatusBadge(status: order.status),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.itemName,
                            style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          if (item.notes.isNotEmpty)
                            Text(
                              'Note: ${item.notes}',
                              style: GoogleFonts.poppins(color: AppColors.error.withOpacity(0.8), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildActionButtons(order),
          ),
        ],
      ),
    ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _buildActionButtons(models.Order order) {
    if (order.status == 'served' || order.status == 'cancelled') return const SizedBox.shrink();

    String actionText = '';
    String nextStatus = '';
    Color color = AppColors.gold;
    IconData icon = Icons.check;

    switch (order.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateStatus(order.id, 'cancelled'),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _updateStatus(order.id, 'cooking'),
                icon: const Icon(Icons.local_fire_department, size: 18),
                label: const Text('Start Cooking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        );
      case 'cooking':
        actionText = 'Mark Ready';
        nextStatus = 'ready';
        color = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case 'ready':
        actionText = 'Mark Served';
        nextStatus = 'served';
        color = AppColors.served;
        icon = Icons.restaurant_rounded;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _updateStatus(order.id, nextStatus),
        icon: Icon(icon, size: 18),
        label: Text(actionText),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
