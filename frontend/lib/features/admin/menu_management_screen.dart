import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/menu_item.dart' as models;
import '../../providers/app_providers.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(menuItemsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Menu Management', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(menuItemsProvider(null)),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      image: item.image.isNotEmpty
                          ? DecorationImage(image: NetworkImage(item.image), fit: BoxFit.cover)
                          : null,
                    ),
                    child: item.image.isEmpty ? const Icon(Icons.fastfood, color: AppColors.gold, size: 26) : null,
                  ),
                  title: Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      color: item.available ? AppColors.textPrimary : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                      decoration: item.available ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '${item.categoryName} • ${item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                    style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.available,
                        onChanged: (value) => _toggleAvailability(item, value),
                        activeColor: AppColors.gold,
                        inactiveTrackColor: AppColors.surfaceLight,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textHint),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                        onPressed: () => _showDeleteDialog(item),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (60 * index).ms).fadeIn().slideX(begin: 0.03);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.add, color: AppColors.background),
        label: Text('Add Item', style: GoogleFonts.poppins(color: AppColors.background, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _toggleAvailability(models.MenuItem item, bool available) async {
    final success = await ref.read(apiServiceProvider).updateMenuItem(item.id, {'available': available});
    if (success) {
      ref.invalidate(menuItemsProvider(null));
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    int? selectedCategory;

    final categoriesAsync = ref.read(categoriesProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Menu Item', style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(nameController, 'Item Name', Icons.restaurant),
              const SizedBox(height: 12),
              _dialogField(descController, 'Description', Icons.description),
              const SizedBox(height: 12),
              _dialogField(priceController, 'Price (ETB)', Icons.monetization_on, isNumber: true),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<int>(
                  hint: const Text('Select Category', style: TextStyle(color: AppColors.textHint)),
                  dropdownColor: AppColors.surfaceLight,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                  onChanged: (v) => selectedCategory = v,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading categories'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty && selectedCategory != null) {
                final success = await ref.read(apiServiceProvider).createMenuItem({
                  'name': nameController.text,
                  'description': descController.text,
                  'price': double.tryParse(priceController.text) ?? 0,
                  'category_id': selectedCategory,
                  'available': true,
                });
                if (success) {
                  ref.invalidate(menuItemsProvider(null));
                  if (mounted) Navigator.pop(context);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(models.MenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    final descController = TextEditingController(text: item.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Item', style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameController, 'Item Name', Icons.restaurant),
            const SizedBox(height: 12),
            _dialogField(descController, 'Description', Icons.description),
            const SizedBox(height: 12),
            _dialogField(priceController, 'Price (ETB)', Icons.monetization_on, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(apiServiceProvider).updateMenuItem(item.id, {
                'name': nameController.text,
                'description': descController.text,
                'price': double.tryParse(priceController.text) ?? item.price,
              });
              if (success) {
                ref.invalidate(menuItemsProvider(null));
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(models.MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Item', style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to delete "${item.name}"?', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await ref.read(apiServiceProvider).deleteMenuItem(item.id);
              if (success) {
                ref.invalidate(menuItemsProvider(null));
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
