import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/table.dart';
import '../../providers/app_providers.dart';

class TablesScreen extends ConsumerStatefulWidget {
  const TablesScreen({super.key});

  @override
  ConsumerState<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesScreen> {
  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tables & QR',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => ref.invalidate(tablesProvider),
          ),
        ],
      ),
      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return const EmptyState(
              icon: Icons.table_restaurant_rounded,
              title: 'No tables',
              subtitle: 'Tap + to add a table',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tablesProvider),
            color: AppColors.gold,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) =>
                  _buildTableCard(tables[index], index),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTableDialog,
        backgroundColor: AppColors.gold,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: AppColors.background),
        label: Text('Add Table',
            style: GoogleFonts.poppins(
                color: AppColors.background, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTableCard(RestaurantTable table, int index) {
    final hasOrders = table.activeOrdersCount > 0;

    return GestureDetector(
      onLongPress: () => _showDeleteDialog(table),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasOrders
                ? AppColors.gold.withOpacity(0.3)
                : AppColors.surfaceLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Table number
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: hasOrders ? AppColors.goldGradient : null,
                color: hasOrders ? null : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${table.number}',
                  style: GoogleFonts.poppins(
                    color: hasOrders
                        ? AppColors.background
                        : AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              table.name.isNotEmpty ? table.name : 'Table ${table.number}',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text('${table.capacity} seats',
                    style: GoogleFonts.poppins(
                        color: AppColors.textHint, fontSize: 11)),
                if (hasOrders) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${table.activeOrdersCount} orders',
                        style: GoogleFonts.poppins(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // QR button
            GestureDetector(
              onTap: () => _generateQr(table),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      table.qrCode.isNotEmpty
                          ? Icons.qr_code_rounded
                          : Icons.qr_code_2_rounded,
                      size: 14,
                      color: table.qrCode.isNotEmpty
                          ? AppColors.success
                          : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      table.qrCode.isNotEmpty ? 'QR Ready' : 'Generate QR',
                      style: GoogleFonts.poppins(
                        color: table.qrCode.isNotEmpty
                            ? AppColors.success
                            : AppColors.textHint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (50 * index).ms).fadeIn().scale(
          begin: const Offset(0.95, 0.95)),
    );
  }

  Future<void> _generateQr(RestaurantTable table) async {
    final api = ref.read(apiServiceProvider);
    final ok = await api.generateQrCode(table.id);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR code generated for Table ${table.number}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      ref.invalidate(tablesProvider);
    }
  }

  void _showAddTableDialog() {
    final numberCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Table',
            style: GoogleFonts.playfairDisplay(
                color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numberCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Table Number',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.tag, color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Capacity (seats)',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.people, color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final num = int.tryParse(numberCtrl.text);
              if (num == null) return;
              final cap = int.tryParse(capacityCtrl.text) ?? 4;
              final ok = await ref.read(apiServiceProvider).createTable({
                'number': num,
                'capacity': cap,
                'is_active': true,
              });
              if (ok) {
                ref.invalidate(tablesProvider);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(RestaurantTable table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Table ${table.number}?',
            style: GoogleFonts.poppins(
                color: AppColors.error, fontWeight: FontWeight.w600)),
        content: Text(
            'This will permanently remove this table.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok =
                  await ref.read(apiServiceProvider).deleteTable(table.id);
              if (ok) {
                ref.invalidate(tablesProvider);
                if (mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
