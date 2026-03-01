import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
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

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() {
      _headerOpacity = (1 - (offset / 200)).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartItemCountProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final menuItemsAsync = ref.watch(filteredMenuItemsProvider(selectedCategoryId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Parallax Image or Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Opacity(
              opacity: _headerOpacity * 0.3,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gold, Colors.transparent],
                  ),
                ),
                child: Image.network(
                  'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?q=80&w=2070&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom AppBar
              SliverToBoxAdapter(
                child: _buildHeader(cartCount),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: _buildSearchBar(),
              ),

              // Categories Horizontal List
              SliverToBoxAdapter(
                child: _buildCategories(categoriesAsync, selectedCategoryId),
              ),

              // Menu Content
              _buildMenuContent(menuItemsAsync),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ],
      ),

      // Floating Cart Button
      floatingActionButton: cartCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              backgroundColor: AppColors.gold,
              elevation: 8,
              icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.background),
              label: Text(
                'View Cart ($cartCount)',
                style: GoogleFonts.poppins(
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
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
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
                    style: GoogleFonts.poppins(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Culinary\nExperience',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),

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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.gold,
                  size: 28,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search for flavors...',
            hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold, size: 24),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildCategories(AsyncValue<List<Category>> categoriesAsync, int? selectedId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            'Categories',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: categoriesAsync.when(
            data: (categories) {
              final allCats = [Category(id: -1, name: 'All', image: ''), ...categories];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                itemCount: allCats.length,
                itemBuilder: (context, index) {
                  final cat = allCats[index];
                  final isSelected = (selectedId == null && cat.id == -1) || selectedId == cat.id;

                  return GestureDetector(
                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id == -1 ? null : cat.id,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.gold : AppColors.surfaceLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : AppColors.surfaceLight,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getCategoryIcon(cat.name),
                            size: 32,
                            color: isSelected ? AppColors.background : AppColors.gold,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.background : AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.2);
                },
              );
            },
            loading: () => _buildCategoryShimmer(),
            error: (_, __) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuContent(AsyncValue<List<models.MenuItem>> menuItemsAsync) {
    return menuItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text('No delicacies found matching your search.', style: TextStyle(color: AppColors.textHint)),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildMenuCard(items[index], index),
              childCount: items.length,
            ),
          ),
        );
      },
      loading: () => SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.68,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildMenuShimmer(),
            childCount: 6,
          ),
        ),
      ),
      error: (e, __) => SliverFillRemaining(
        child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildMenuCard(models.MenuItem item, int index) {
    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.8),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 12,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image.startsWith('http') ? item.image : '${AppConstants.baseUrl}${item.image}',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderIcon(item),
                            )
                          : _buildPlaceholderIcon(item),
                    ),
                  ),
                  
                  // Popular Badge
                  if (item.isPopular)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, size: 14, color: AppColors.background),
                            const SizedBox(width: 4),
                            Text(
                              'BEST',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.background,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Prep Time
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${item.preparationTime}m',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info Section
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: GoogleFonts.poppins(
                        color: AppColors.textHint,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                          style: GoogleFonts.poppins(
                            color: AppColors.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _buildAddButton(item),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (50 * index).ms).fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildPlaceholderIcon(models.MenuItem item) {
    return Center(
      child: Icon(
        Icons.restaurant_rounded,
        size: 50,
        color: AppColors.gold.withOpacity(0.3),
      ),
    );
  }

  Widget _buildAddButton(models.MenuItem item) {
    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).addItem(item);
        _vibrate();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.goldLight, AppColors.gold],
          ),
        ),
        child: const Icon(Icons.add, color: AppColors.background, size: 24),
      ),
    );
  }

  void _vibrate() {
    // Simple feedback logic
  }

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('burger')) return Icons.lunch_dining_rounded;
    if (name.contains('pizza')) return Icons.local_pizza_rounded;
    if (name.contains('drink') || name.contains('cafe')) return Icons.coffee_rounded;
    if (name.contains('dessert')) return Icons.icecream_rounded;
    if (name.contains('ethiopian')) return Icons.restaurant_rounded;
    return Icons.flatware_rounded;
  }

  Widget _buildCategoryShimmer() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      itemCount: 5,
      itemBuilder: (context, _) => Shimmer.fromColors(
        baseColor: AppColors.surfaceLight,
        highlightColor: AppColors.surface,
        child: Container(
          width: 80,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),

          // Detailed Hero Image
          Hero(
            tag: 'item-${widget.item.id}',
            child: Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                image: widget.item.image.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(
                          widget.item.image.startsWith('http') ? widget.item.image : '${AppConstants.baseUrl}${widget.item.image}',
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.item.image.isEmpty
                  ? const Center(child: Icon(Icons.restaurant_rounded, size: 80, color: AppColors.gold))
                  : null,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.item.name,
                  style: GoogleFonts.poppins(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${widget.item.price.toStringAsFixed(0)} ${AppConstants.currency}',
                style: GoogleFonts.poppins(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            widget.item.description,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Customization Notes
          TextField(
            controller: _notesController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Add special instructions...',
              hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceLight.withOpacity(0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.gold),
            ),
          ),

          const SizedBox(height: 28),

          // Quantity and Action
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _qtyButton(Icons.remove, () {
                      if (_quantity > 1) setState(() => _quantity--);
                    }),
                    Text(
                      '$_quantity',
                      style: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    _qtyButton(Icons.add, () => setState(() => _quantity++)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < _quantity; i++) {
                        ref.read(cartProvider.notifier).addItem(widget.item);
                      }
                      if (_notesController.text.isNotEmpty) {
                        ref.read(cartProvider.notifier).updateNotes(widget.item.id, _notesController.text);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      elevation: 4,
                      shadowColor: AppColors.gold.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      'Add to Cart   ${(widget.item.price * _quantity).toStringAsFixed(0)} ${AppConstants.currency}',
                      style: GoogleFonts.poppins(color: AppColors.background, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Icon(icon, color: AppColors.gold, size: 24),
        ),
      ),
    );
  }
}
