import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final List<_AdminMenuItem> _items = [
    _AdminMenuItem(id: 1, name: 'Classic Burger', category: 'Burgers', price: 180, available: true),
    _AdminMenuItem(id: 2, name: 'Cheese Burger', category: 'Burgers', price: 220, available: true),
    _AdminMenuItem(id: 3, name: 'Chicken Burger', category: 'Burgers', price: 200, available: false),
    _AdminMenuItem(id: 4, name: 'Margherita Pizza', category: 'Pizza', price: 280, available: true),
    _AdminMenuItem(id: 5, name: 'Pepperoni Pizza', category: 'Pizza', price: 320, available: true),
    _AdminMenuItem(id: 6, name: 'Fresh Juice', category: 'Drinks', price: 80, available: true),
    _AdminMenuItem(id: 7, name: 'Doro Wot Special', category: 'Specials', price: 350, available: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fastfood, color: AppColors.gold, size: 26),
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  color: item.available ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  decoration: item.available ? null : TextDecoration.lineThrough,
                ),
              ),
              subtitle: Text(
                '${item.category} • ${item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle availability
                  Switch(
                    value: item.available,
                    onChanged: (value) {
                      setState(() => _items[index] = _AdminMenuItem(
                        id: item.id,
                        name: item.name,
                        category: item.category,
                        price: item.price,
                        available: value,
                      ));
                    },
                    activeColor: AppColors.gold,
                    inactiveTrackColor: AppColors.surfaceLight,
                  ),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textHint),
                    onPressed: () => _showEditDialog(item),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 20, color: AppColors.error),
                    onPressed: () => _showDeleteDialog(item),
                  ),
                ],
              ),
            ),
          ).animate(delay: (60 * index).ms).fadeIn().slideX(begin: 0.03);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.add, color: AppColors.background),
        label: const Text('Add Item', style: TextStyle(color: AppColors.background, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Burgers';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Menu Item', style: TextStyle(color: AppColors.gold)),
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
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: AppColors.surfaceLight,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Burgers', 'Pizza', 'Drinks', 'Desserts', 'Specials']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppColors.textPrimary))))
                    .toList(),
                onChanged: (v) => selectedCategory = v ?? selectedCategory,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                setState(() {
                  _items.add(_AdminMenuItem(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: nameController.text,
                    category: selectedCategory,
                    price: double.tryParse(priceController.text) ?? 0,
                    available: true,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(_AdminMenuItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Item', style: TextStyle(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameController, 'Item Name', Icons.restaurant),
            const SizedBox(height: 12),
            _dialogField(priceController, 'Price (ETB)', Icons.monetization_on, isNumber: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final idx = _items.indexWhere((e) => e.id == item.id);
              if (idx >= 0) {
                setState(() {
                  _items[idx] = _AdminMenuItem(
                    id: item.id,
                    name: nameController.text,
                    category: item.category,
                    price: double.tryParse(priceController.text) ?? item.price,
                    available: item.available,
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(_AdminMenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Item', style: TextStyle(color: AppColors.error)),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _items.removeWhere((e) => e.id == item.id));
              Navigator.pop(context);
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  final int id;
  final String name;
  final String category;
  final double price;
  final bool available;

  _AdminMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
  });
}
