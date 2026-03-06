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

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(cashierOrdersProvider);

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
                  child: const Icon(Icons.point_of_sale_rounded,
                      color: AppColors.background, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Cashier',
                    style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.w700, fontSize: 20)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 22),
                onPressed: () => ref.invalidate(cashierOrdersProvider),
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
                labelColor: AppColors.gold,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.gold,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 13),
                unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Unpaid'),
                  Tab(text: 'Paid'),
                ],
              ),
            ),
          ),
        ],
        body: ordersAsync.when(
          data: (orders) {
            final unpaid =
                orders.where((o) => o.paymentStatus == 'unpaid').toList();
            final paid =
                orders.where((o) => o.paymentStatus == 'paid').toList();

            return Column(
              children: [
                // Summary bar
                _buildSummaryBar(orders, unpaid.length, paid.length),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(orders),
                      _buildOrderList(unpaid),
                      _buildOrderList(paid),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, _) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(
      List<models.Order> allOrders, int unpaidCount, int paidCount) {
    final totalRevenue = allOrders
        .where((o) => o.paymentStatus == 'paid')
        .fold<double>(0, (sum, o) => sum + o.total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _buildSummaryChip(
            '$unpaidCount',
            'Unpaid',
            AppColors.pending,
            Icons.receipt_long_rounded,
          ),
          const SizedBox(width: 10),
          _buildSummaryChip(
            '$paidCount',
            'Paid',
            AppColors.success,
            Icons.check_circle_rounded,
          ),
          const SizedBox(width: 10),
          _buildSummaryChip(
            '${totalRevenue.toStringAsFixed(0)}',
            AppConstants.currency,
            AppColors.gold,
            Icons.monetization_on_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
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
        icon: Icons.receipt_long_outlined,
        title: 'No orders',
        subtitle: 'Orders will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(cashierOrdersProvider),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _CashierOrderCard(order: orders[index], index: index),
      ),
    );
  }
}

class _CashierOrderCard extends ConsumerStatefulWidget {
  final models.Order order;
  final int index;

  const _CashierOrderCard({required this.order, required this.index});

  @override
  ConsumerState<_CashierOrderCard> createState() => _CashierOrderCardState();
}

class _CashierOrderCardState extends ConsumerState<_CashierOrderCard> {
  bool _isProcessing = false;

  void _showPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Payment Method',
                style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                'Total: ${widget.order.total.toStringAsFixed(0)} ${AppConstants.currency}',
                style: GoogleFonts.poppins(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            _buildPaymentChoice(
              ctx,
              'Cash',
              'Mark as cash payment',
              Icons.money_rounded,
              AppColors.success,
              () {
                Navigator.pop(ctx);
                _markPaid('cash');
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentChoice(
              ctx,
              'Card',
              'Mark as card payment',
              Icons.credit_card_rounded,
              AppColors.info,
              () {
                Navigator.pop(ctx);
                _markPaid('card');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentChoice(BuildContext ctx, String label, String subtitle,
      IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          color: AppColors.textHint, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _markPaid(String paymentMethod) async {
    setState(() => _isProcessing = true);
    final api = ref.read(apiServiceProvider);
    final ok = await api.markOrderPaid(widget.order.id,
        paymentMethod: paymentMethod);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Order #${widget.order.orderNumber} paid ($paymentMethod)'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(cashierOrdersProvider);
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPaid = order.paymentStatus == 'paid';
    final borderColor =
        isPaid ? AppColors.success.withOpacity(0.2) : AppColors.surfaceLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withOpacity(0.04)
                  : AppColors.pending.withOpacity(0.04),
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
                    'T${order.tableNumber > 0 ? order.tableNumber : '-'}',
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
                        'Order #${order.orderNumber}',
                        style: GoogleFonts.poppins(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          StatusBadge(status: order.status),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPaymentBadge(isPaid),
              ],
            ),
          ),

          // Items summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('${item.quantity}x',
                                style: GoogleFonts.poppins(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item.itemName,
                                  style: GoogleFonts.poppins(
                                      color: AppColors.textPrimary,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                                '${(item.itemPrice * item.quantity).toStringAsFixed(0)} ${AppConstants.currency}',
                                style: GoogleFonts.poppins(
                                    color: AppColors.textHint, fontSize: 12)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Total + Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total',
                          style: GoogleFonts.poppins(
                              color: AppColors.textHint, fontSize: 11)),
                      Text(
                        '${order.total.toStringAsFixed(0)} ${AppConstants.currency}',
                        style: GoogleFonts.poppins(
                          color: AppColors.gold,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPaid)
                  SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _showPaymentMethodDialog,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Mark Paid'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text('Paid',
                            style: GoogleFonts.poppins(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (60 * widget.index).ms).fadeIn().slideY(begin: 0.04);
  }

  Widget _buildPaymentBadge(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPaid
            ? AppColors.success.withOpacity(0.12)
            : AppColors.pending.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isPaid ? 'PAID' : 'UNPAID',
        style: GoogleFonts.poppins(
          color: isPaid ? AppColors.success : AppColors.pending,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
