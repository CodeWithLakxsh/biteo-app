// ============================================================
// lib/features/vendor/data/repositories/menu_repository_impl.dart
// ✅ FINAL STABLE VERSION (BUG FIXED PROPERLY)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/menu_item_entity.dart';
import '../../domain/repositories/i_menu_repository.dart';

class MenuRepositoryImpl implements IMenuRepository {
  final FirebaseFirestore _db;
  final Logger _log;

  MenuRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  // ============================================================
  // ✅ WATCH MENU ITEMS (FIXED — NO FILTER REMOVAL)
  // ============================================================
  @override
  Stream<List<MenuItemEntity>> watchMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snap) {
      final items = snap.docs.map((doc) {
        final data = doc.data();

        final item = MenuItemEntity.fromFirestore(
          data,
          doc.id,
          vendorId,
        );

        // 🔥 FIX: DO NOT REMOVE ITEMS
        // Let UI handle stock & availability
        return item;
      }).toList();

      // ✅ SORT (keep your logic)
      items.sort((a, b) {
        if (a.isInStock && !b.isInStock) return -1;
        if (!a.isInStock && b.isInStock) return 1;

        final catCompare = a.category.compareTo(b.category);
        if (catCompare != 0) return catCompare;

        return a.name.compareTo(b.name);
      });

      _log.d('[Menu] Fetched ${items.length} items for vendor $vendorId');

      return items;
    });
  }

  // ============================================================
  // ✅ GET SINGLE ITEM (UNCHANGED)
  // ============================================================
  @override
  Future<MenuItemEntity?> getMenuItem({
    required String vendorId,
    required String menuItemId,
  }) async {
    try {
      final snap = await _db
          .collection('vendors')
          .doc(vendorId)
          .collection('menu')
          .doc(menuItemId)
          .get();

      if (!snap.exists || snap.data() == null) return null;

      return MenuItemEntity.fromFirestore(
        snap.data()!,
        snap.id,
        vendorId,
      );
    } catch (e) {
      _log.e('[Menu] Error fetching item $menuItemId', error: e);
      return null;
    }
  }
}