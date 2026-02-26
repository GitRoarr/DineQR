import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class ItemDetailScreen extends ConsumerWidget {
  final int itemId;
  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Item Details')),
      body: Center(
        child: Text(
          'Item #$itemId',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
        ),
      ),
    );
  }
}
