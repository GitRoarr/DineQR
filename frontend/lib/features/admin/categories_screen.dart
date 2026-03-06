import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/category.dart';
import '../../providers/app_providers.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Categories',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => ref.invalidate(categoriesProvider),
          ),
        ],
      ),
      body: catsAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_rounded,
              title: 'No categories',
              subtitle: 'Tap + to create a category',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(categoriesProvider),
            color: AppColors.gold,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: categories.length,
              itemBuilder: (context, index) =>
                  _buildCategoryCard(categories[index], index),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.gold,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: AppColors.background),
        label: Text('Add Category',
            style: GoogleFonts.poppins(
                color: AppColors.background, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCategoryCard(Category cat, int index) {
    final icons = {
      'breakfast': Icons.free_breakfast_rounded,
      'mains': Icons.restaurant_rounded,
      'drinks': Icons.local_cafe_rounded,
      'desserts': Icons.icecream_rounded,
      'burger': Icons.lunch_dining_rounded,
      'pizza': Icons.local_pizza_rounded,
      'ethiopian': Icons.restaurant_menu_rounded,
    };
    final iconData = icons.entries
            .where((e) => cat.name.toLowerCase().contains(e.key))
            .firstOrNull
            ?.value ??
        Icons.category_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(iconData, color: AppColors.gold, size: 26),
        ),
        title: Text(
          cat.name,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textHint, size: 22),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          offset: const Offset(0, 40),
          onSelected: (action) {
            if (action == 'edit') _showEditDialog(cat);
            if (action == 'delete') _showDeleteDialog(cat);
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 18, color: AppColors.gold.withOpacity(0.8)),
                  const SizedBox(width: 10),
                  Text('Edit',
                      style: GoogleFonts.poppins(
                          color: AppColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_rounded,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text('Delete',
                      style: GoogleFonts.poppins(
                          color: AppColors.error, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.03);
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Category',
            style: GoogleFonts.playfairDisplay(
                color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Category Name',
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon:
                const Icon(Icons.category, color: AppColors.textHint, size: 20),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final ok = await ref
                  .read(apiServiceProvider)
                  .createCategory({'name': nameCtrl.text});
              if (ok) {
                ref.invalidate(categoriesProvider);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Category cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Category',
            style: GoogleFonts.playfairDisplay(
                color: AppColors.gold, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Category Name',
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon:
                const Icon(Icons.category, color: AppColors.textHint, size: 20),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final ok = await ref
                  .read(apiServiceProvider)
                  .updateCategory(cat.id, {'name': nameCtrl.text});
              if (ok) {
                ref.invalidate(categoriesProvider);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${cat.name}"?',
            style: GoogleFonts.poppins(
                color: AppColors.error, fontWeight: FontWeight.w600)),
        content: Text(
            'This will also delete all menu items in this category.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok =
                  await ref.read(apiServiceProvider).deleteCategory(cat.id);
              if (ok) {
                ref.invalidate(categoriesProvider);
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
