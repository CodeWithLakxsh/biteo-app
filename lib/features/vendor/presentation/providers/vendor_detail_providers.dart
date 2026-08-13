// ============================================================
// lib/features/vendor/presentation/providers/vendor_detail_providers.dart
// CTO FIX: Used standard Notifier universally. Replaced 
// AutoDisposeNotifier which was missing in this Riverpod version.
// Your UI's `.select()` methods will work perfectly here.
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/entities/vendor_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/repositories/i_menu_repository.dart';

// ── Menu Repository ───────────────────────────────────────────
final menuRepositoryProvider = Provider<IMenuRepository>(
  (_) => MenuRepositoryImpl(),
);

// ── Real-time menu items stream ───────────────────────────────
final menuItemsProvider = StreamProvider.autoDispose
    .family<List<MenuItemEntity>, String>((ref, vendorId) {
  return ref.watch(menuRepositoryProvider).watchMenuItems(vendorId);
});

// ── Selected Vendor ───────────────────────────────────────────
class SelectedVendorNotifier extends Notifier<VendorEntity?> {
  @override
  VendorEntity? build() => null;
  
  // UI uses this to update state
  void select(VendorEntity? vendor) => state = vendor;
}

final selectedVendorProvider = NotifierProvider<SelectedVendorNotifier, VendorEntity?>(
  SelectedVendorNotifier.new,
);

// ── Selected Menu Category ────────────────────────────────────
// CTO FIX: Changed from AutoDisposeNotifier to standard Notifier
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  // UI uses this to update state
  void select(String? category) => state = category;
}

final selectedMenuCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String?>(
  SelectedCategoryNotifier.new,
);

// ── Grouped Menu Items ────────────────────────────────────────
final groupedMenuProvider = Provider.autoDispose.family<
    Map<String, List<MenuItemEntity>>, String>((ref, vendorId) {
  final itemsAsync = ref.watch(menuItemsProvider(vendorId));
  final isPureVeg = ref.watch(isPureVegProvider);
  final selectedCategory = ref.watch(selectedMenuCategoryProvider);

  return itemsAsync.when(
    loading: () => <String, List<MenuItemEntity>>{},
    error: (_, __) => <String, List<MenuItemEntity>>{},
    data: (items) {
      var filtered = isPureVeg ? items.where((i) => i.isVeg).toList() : items;
      
      if (selectedCategory != null) {
        filtered = filtered.where((i) => i.category == selectedCategory).toList();
      }

      final Map<String, List<MenuItemEntity>> grouped = {};
      for (final item in filtered) {
        grouped.putIfAbsent(item.category, () => []).add(item);
      }
      return grouped;
    },
  );
});

// ── Available Categories ──────────────────────────────────────
final menuCategoriesProvider =
    Provider.autoDispose.family<List<String>, String>((ref, vendorId) {
  final itemsAsync = ref.watch(menuItemsProvider(vendorId));
  return itemsAsync.maybeWhen(
    data: (items) => items.map((i) => i.category).toSet().toList()..sort(),
    orElse: () => <String>[],
  );
});