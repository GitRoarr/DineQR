import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/category.dart';
import '../../models/menu_item.dart' as models;
import '../../providers/app_providers.dart';

class MenuScreen extends ConsumerStatefulWidget {
  final int? tableId;
  const MenuScreen({super.key, this.tableId});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // Demo data for offline/testing
  final List<Category> _demoCategories = [
    Category(id: 0, name: 'All', image: ''),
    Category(id: 1, name: 'Burgers', image: ''),
    Category(id: 2, name: 'Pizza', image: ''),
    Category(id: 3, name: 'Drinks', image: ''),
    Category(id: 4, name: 'Desserts', image: ''),
    Category(id: 5, name: 'Specials', image: ''),
  ];

  final List<models.MenuItem> _demoItems = [
    models.MenuItem(id: 1, name: 'Classic Burger', description: 'Juicy beef patty with fresh lettuce, tomato & cheese', price: 180, image: '', categoryId: 1, categoryName: 'Burgers'),
    models.MenuItem(id: 2, name: 'Cheese Burger', description: 'Double cheese with caramelized onions', price: 220, image: '', categoryId: 1, categoryName: 'Burgers'),
    models.MenuItem(id: 3, name: 'Chicken Burger', description: 'Crispy chicken with special sauce', price: 200, image: '', categoryId: 1, categoryName: 'Burgers'),
    models.MenuItem(id: 4, name: 'Margherita Pizza', description: 'Traditional Italian with fresh mozzarella', price: 280, image: '', categoryId: 2, categoryName: 'Pizza'),
    models.MenuItem(id: 5, name: 'Pepperoni Pizza', description: 'Loaded with pepperoni & cheese', price: 320, image: '', categoryId: 2, categoryName: 'Pizza'),
    models.MenuItem(id: 6, name: 'BBQ Pizza', description: 'BBQ sauce, chicken, onions & peppers', price: 350, image: '', categoryId: 2, categoryName: 'Pizza'),
    models.MenuItem(id: 7, name: 'Fresh Juice', description: 'Orange, mango or mixed fruit', price: 80, image: '', categoryId: 3, categoryName: 'Drinks'),
    models.MenuItem(id: 8, name: 'Smoothie', description: 'Banana, strawberry & yogurt blend', price: 120, image: '', categoryId: 3, categoryName: 'Drinks'),
    models.MenuItem(id: 9, name: 'Iced Coffee', description: 'Cold brew with vanilla cream', price: 100, image: '', categoryId: 3, categoryName: 'Drinks'),
    models.MenuItem(id: 10, name: 'Chocolate Cake', description: 'Rich chocolate layer cake', price: 150, image: '', categoryId: 4, categoryName: 'Desserts'),
    models.MenuItem(id: 11, name: 'Tiramisu', description: 'Classic Italian coffee dessert', price: 180, image: '', categoryId: 4, categoryName: 'Desserts'),
    models.MenuItem(id: 12, name: 'Doro Wot Special', description: 'Traditional Ethiopian chicken stew with injera', price: 350, image: '', categoryId: 5, categoryName: 'Specials'),
  ];

  int _selectedCategoryIndex = 0;

  List<models.MenuItem> get _filteredItems {
    final query = _searchController.text.toLowerCase();
    var items = _demoItems;

    if (_selectedCategoryIndex > 0) {
      items = items.where((i) => i.categoryId == _demoCategories[_selectedCategoryIndex].id).toList();
    }

    if (query.isNotEmpty) {
      items = items.where((i) =>
        i.name.toLowerCase().contains(query) ||
        i.description.toLowerCase().contains(query)
      ).toList();
    }

    return items;
  }

  final Map<int, IconData> _categoryIcons = {
    0: Icons.restaurant_menu_rounded,
    1: Icons.lunch_dining_rounded,
    2: Icons.local_pizza_rounded,
    3: Icons.local_cafe_rounded,
    4: Icons.cake_rounded,
    5: Icons.star_rounded,
  };

  final Map<int, IconData> _foodIcons = {
    1: Icons.lunch_dining_rounded,
    2: Icons.local_pizza_rounded,
    3: Icons.local_cafe_rounded,
    4: Icons.cake_rounded,
    5: Icons.star_rounded,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(cartCount),

            // Search Bar
            _buildSearchBar(),

            // Categories
            _buildCategories(),

            // Menu Grid
            Expanded(child: _buildMenuGrid()),
          ],
        ),
      ),

      // Floating Cart Button
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              backgroundColor: AppColors.gold,
              icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.background),
              label: Text(
                'Cart ($cartCount)',
                style: const TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut)
          : null,
    );
  }

  Widget _buildHeader(int cartCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_restaurant, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Table ${widget.tableId ?? '?'}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'What would you like\nto order?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

          // Cart icon
          GestureDetector(
            onTap: () => context.push('/cart'),
            child: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text(
                '$cartCount',
                style: const TextStyle(color: AppColors.background, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: AppColors.gold,
                padding: EdgeInsets.all(6),
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search menu...',
            hintStyle: const TextStyle(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        itemCount: _demoCategories.length,
        itemBuilder: (context, index) {
          final cat = _demoCategories[index];
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(18),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.surfaceLight),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _categoryIcons[index] ?? Icons.fastfood,
                    size: 30,
                    color: isSelected ? AppColors.background : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.background : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate(delay: (100 * index).ms).fadeIn().slideX(begin: 0.2);
        },
      ),
    );
  }

  Widget _buildMenuGrid() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'No items found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMenuCard(item, index);
      },
    );
  }

  Widget _buildMenuCard(models.MenuItem item, int index) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Center(
                  child: Icon(
                    _foodIcons[item.categoryId] ?? Icons.fastfood_rounded,
                    size: 48,
                    color: AppColors.gold.withOpacity(0.6),
                  ),
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item.name} added to cart'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.surfaceLight,
                              ),
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.background,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.1);
  }

  void _showItemDetail(models.MenuItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ItemDetailSheet(item: item),
    );
  }
}

class _ItemDetailSheet extends ConsumerStatefulWidget {
  final models.MenuItem item;
  const _ItemDetailSheet({required this.item});

  @override
  ConsumerState<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<_ItemDetailSheet> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.fastfood_rounded, size: 80, color: AppColors.gold),
            ),

            const SizedBox(height: 20),

            // Name & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${widget.item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              widget.item.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            // Special notes
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Special instructions (e.g. no spice)',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Quantity + Add to cart
            Row(
              children: [
                // Quantity selector
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _qtyButton(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _qtyButton(Icons.add, () => setState(() => _quantity++)),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Add to cart button
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        for (int i = 0; i < _quantity; i++) {
                          ref.read(cartProvider.notifier).addItem(widget.item);
                        }
                        if (_notesController.text.isNotEmpty) {
                          ref.read(cartProvider.notifier).updateNotes(
                            widget.item.id,
                            _notesController.text,
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.item.name} x$_quantity added'),
                            backgroundColor: AppColors.surfaceLight,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Add  ${(widget.item.price * _quantity).toStringAsFixed(0)} ${AppConstants.currency}',
                        style: const TextStyle(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
      ),
    );
  }
}
