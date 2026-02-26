import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/order.dart';
import '../../providers/app_providers.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_DemoOrder> _orders = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDemoOrders();
    _listenToSocket();
  }

  void _loadDemoOrders() {
    _orders = [
      _DemoOrder(id: 1001, tableNumber: 3, status: 'pending', items: ['Burger x2', 'Juice x1'], total: 460, time: '2 min ago'),
      _DemoOrder(id: 1002, tableNumber: 7, status: 'pending', items: ['Pizza x1', 'Smoothie x2'], total: 520, time: '5 min ago'),
      _DemoOrder(id: 1003, tableNumber: 1, status: 'cooking', items: ['Doro Wot Special x1', 'Coffee x2'], total: 550, time: '10 min ago'),
      _DemoOrder(id: 1004, tableNumber: 12, status: 'cooking', items: ['Cheese Burger x3', 'Fries x3'], total: 780, time: '15 min ago'),
      _DemoOrder(id: 1005, tableNumber: 5, status: 'ready', items: ['Tiramisu x2', 'Iced Coffee x2'], total: 560, time: '20 min ago'),
      _DemoOrder(id: 1006, tableNumber: 9, status: 'served', items: ['BBQ Pizza x1', 'Fresh Juice x1'], total: 430, time: '30 min ago'),
    ];
  }

  void _listenToSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.onNewOrder = (data) {
      setState(() {
        _orders.insert(0, _DemoOrder(
          id: DateTime.now().millisecondsSinceEpoch,
          tableNumber: data['table'] ?? 0,
          status: 'pending',
          items: ['New order items'],
          total: (data['total'] ?? 0).toDouble(),
          time: 'Just now',
        ));
      });
    };
  }

  List<_DemoOrder> get _filteredOrders {
    if (_selectedFilter == 'all') return _orders;
    return _orders.where((o) => o.status == _selectedFilter).toList();
  }

  void _updateStatus(int orderId, String newStatus) {
    setState(() {
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = _DemoOrder(
          id: _orders[index].id,
          tableNumber: _orders[index].tableNumber,
          status: newStatus,
          items: _orders[index].items,
          total: _orders[index].total,
          time: _orders[index].time,
        );
      }
    });

    // Emit status update via socket
    final socket = ref.read(socketServiceProvider);
    socket.emitStatusUpdate(orderId, newStatus);

    // Also update via API
    ref.read(apiServiceProvider).updateOrderStatus(orderId, newStatus);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _orders.where((o) => o.status == 'pending').length;
    final cookingCount = _orders.where((o) => o.status == 'cooking').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_rounded, color: AppColors.gold, size: 24),
            const SizedBox(width: 8),
            const Text('Kitchen'),
          ],
        ),
        actions: [
          // Pending badge
          if (pendingCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$pendingCount new',
                    style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterRow(),

          // Stats row
          _buildStatsRow(pendingCount, cookingCount),

          // Orders list
          Expanded(
            child: _filteredOrders.isEmpty
                ? const EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'All caught up!',
                    subtitle: 'No orders in this category',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index], index);
                    },
                  ),
          ),
        ],
      ),
    );
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
                    style: TextStyle(
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

  Widget _buildStatsRow(int pending, int cooking) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Pending', '$pending', AppColors.pending, Icons.access_time),
          const SizedBox(width: 12),
          _buildStatCard('Cooking', '$cooking', AppColors.cooking, Icons.local_fire_department),
          const SizedBox(width: 12),
          _buildStatCard('Ready', '${_orders.where((o) => o.status == "ready").length}', AppColors.ready, Icons.check_circle),
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
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(_DemoOrder order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: order.status == 'pending'
              ? AppColors.pending.withOpacity(0.3)
              : AppColors.surfaceLight,
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
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '#${order.id}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    StatusBadge(status: order.status),
                    const SizedBox(width: 8),
                    Text(
                      order.time,
                      style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Text(item, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  ],
                ),
              )).toList(),
            ),
          ),

          // Total
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ${order.total.toStringAsFixed(0)} ${AppConstants.currency}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

  Widget _buildActionButtons(_DemoOrder order) {
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
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(order.id, 'ready'),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mark Ready'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(order.id, 'served'),
            icon: const Icon(Icons.restaurant, size: 18),
            label: const Text('Mark Served'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.served,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _DemoOrder {
  final int id;
  final int tableNumber;
  final String status;
  final List<String> items;
  final double total;
  final String time;

  _DemoOrder({
    required this.id,
    required this.tableNumber,
    required this.status,
    required this.items,
    required this.total,
    required this.time,
  });
}
