// ============================================================
// lib/features/vendor/domain/repositories/i_menu_repository.dart
// ============================================================
import '../entities/menu_item_entity.dart';

abstract class IMenuRepository {
  /// Real-time stream of all menu items for a vendor.
  /// Only returns items where is_available = true.
  Stream<List<MenuItemEntity>> watchMenuItems(String vendorId);

  /// One-time read of a single menu item.
  /// Used by Cart to snapshot price at time of add.
  Future<MenuItemEntity?> getMenuItem(
      {required String vendorId, required String menuItemId});
}