// ============================================================
// lib/features/cart/data/repositories/cart_repository_impl.dart
// ============================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../../vendor/domain/entities/menu_item_entity.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/i_cart_repository.dart';

class CartRepositoryImpl implements ICartRepository {
  final FirebaseFirestore _db;
  final Logger _log;

  CartRepositoryImpl({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _log = Logger(printer: PrettyPrinter(methodCount: 0));

  static const _carts = 'active_carts';
  static const _vendors = 'vendors';
  static const _menus = 'menu';

  // ── watchCart ─────────────────────────────────────────────
  @override
  Stream<CartEntity?> watchCart(String userId) {
    return _db.collection(_carts).doc(userId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return _fromFirestore(snap);
    });
  }

  // ── addItem ───────────────────────────────────────────────
  @override
  Future<Either<CartFailure, CartEntity>> addItem({
    required String userId,
    required String vendorId,
    required String vendorName,
    required MenuItemEntity item,
    required int quantity,
    required int platformFeePercent,
    required int cartExpiryMinutes,
  }) async {
    try {
      final cartRef = _db.collection(_carts).doc(userId);
      final menuRef = _db
          .collection(_vendors)
          .doc(vendorId)
          .collection(_menus)
          .doc(item.id);

      CartEntity? result;
      CartFailure? failure;

      await _db.runTransaction((tx) async {
        final cartSnap = await tx.get(cartRef);
        final menuSnap = await tx.get(menuRef);

        // Validate: item still exists and has stock.
        if (!menuSnap.exists) {
          failure = const CartFailure.itemNotFound();
          return;
        }

        final menuData = menuSnap.data()!;

final currentStock =
    (menuData['available_quantity'] as num?)?.toInt() ?? 10;

        if (currentStock < quantity) {
          failure = CartFailure.insufficientStock(available: currentStock);
          return;
        }

        // Validate: same vendor or empty cart.
        List<CartItemEntity> existingItems = [];
        String? existingVendorId;
        DateTime? existingCreatedAt;

        if (cartSnap.exists && cartSnap.data() != null) {
          final existing = _fromFirestore(cartSnap);
          existingVendorId = existing.vendorId;

          // Blocked: cart belongs to a different vendor.
          if (existingVendorId != vendorId) {
            failure = const CartFailure.differentVendor();
            return;
          }

          // Blocked: cart is locked (payment in progress).
          if (existing.isLocked) {
            failure = const CartFailure.cartLocked();
            return;
          }

          existingItems = existing.items;
          existingCreatedAt = existing.createdAt;
        }

        // ── Compute new item list ──
        final itemIndex =
            existingItems.indexWhere((i) => i.menuItemId == item.id);
        List<CartItemEntity> newItems;

        if (itemIndex >= 0) {
          // Increase quantity of existing item.
          final updated = existingItems[itemIndex]
              .copyWith(quantity: existingItems[itemIndex].quantity + quantity);
          newItems = List.from(existingItems)..[itemIndex] = updated;
        } else {
          // Add new item.
          newItems = [
            ...existingItems,
            CartItemEntity(
              menuItemId: item.id,
              vendorId: vendorId,
              name: item.name,
              imageUrl: item.imageUrl,
              category: item.category,
              unitPricePaise: item.discountedPricePaise,
              quantity: quantity,
              isVeg: item.isVeg,
            ),
          ];
        }

        // ── Compute pricing ──
        final subtotal =
            newItems.fold<int>(0, (sum, i) => sum + i.lineTotalPaise);
        final platformFee = 1000;
        final total = subtotal + platformFee;
        final now = DateTime.now();
        final expiresAt = now.add(Duration(minutes: cartExpiryMinutes));

        final cartData = {
          'user_id': userId,
          'vendor_id': vendorId,
          'vendor_name': vendorName,
          'items': newItems
              .map((i) => {
                    'menu_item_id': i.menuItemId,
                    'vendor_id': i.vendorId,
                    'name': i.name,
                    if (i.imageUrl != null) 'image_url': i.imageUrl,
                    'category': i.category,
                    'unit_price': i.unitPricePaise,
                    'quantity': i.quantity,
                    'is_veg': i.isVeg,
                  })
              .toList(),
          'pricing': {
            'subtotal': subtotal,
            'platform_fee': platformFee,
            'total': total,
          },
          'expiry': {
            'created_at': existingCreatedAt != null
                ? Timestamp.fromDate(existingCreatedAt)
                : FieldValue.serverTimestamp(),
            'expires_at': Timestamp.fromDate(expiresAt),
            'is_locked': false,
          },
          'pickup': {
            'mode': 'in_store',
            'selected_address': null,
          },
        };

        // ── Firestore mutations (both inside the transaction) ──
        tx.set(cartRef, cartData);
        tx.update(menuRef, {
  'available_quantity': currentStock - quantity,
});

        result = CartEntity(
          userId: userId,
          vendorId: vendorId,
          vendorName: vendorName,
          items: newItems,
          subtotalPaise: subtotal,
          platformFeePaise: platformFee,
          totalPaise: total,
          expiresAt: expiresAt,
          createdAt: existingCreatedAt ?? now,
        );
      });

      if (failure != null) return left(failure!);
      return right(result!);
    } on FirebaseException catch (e) {
      _log.e('[Cart] Firebase error in addItem: ${e.code}', error: e);
      return left(CartFailure.unknown(message: e.message));
    } catch (e) {
      _log.e('[Cart] Unknown error in addItem', error: e);
      return left(CartFailure.unknown(message: e.toString()));
    }
  }

  // ── removeItem ────────────────────────────────────────────
  @override
  Future<Either<CartFailure, CartEntity?>> removeItem({
    required String userId,
    required String menuItemId,
    required String vendorId,
  }) async {
    try {
      final cartRef = _db.collection(_carts).doc(userId);
      final menuRef = _db
          .collection(_vendors)
          .doc(vendorId)
          .collection(_menus)
          .doc(menuItemId);

      CartEntity? result;
      CartFailure? failure;

      await _db.runTransaction((tx) async {
        final cartSnap = await tx.get(cartRef);
        final menuSnap = await tx.get(menuRef);

        if (!cartSnap.exists) return;

        final cart = _fromFirestore(cartSnap);
        if (cart.isLocked) {
          failure = const CartFailure.cartLocked();
          return;
        }

        final itemIndex =
            cart.items.indexWhere((i) => i.menuItemId == menuItemId);
        if (itemIndex < 0) return;

        final removedItem = cart.items[itemIndex];
        List<CartItemEntity> newItems;

        if (removedItem.quantity > 1) {
          // Decrement quantity.
          newItems = List.from(cart.items)
            ..[itemIndex] = removedItem.copyWith(
              quantity: removedItem.quantity - 1,
            );
        } else {
          // Remove entirely.
          newItems = List.from(cart.items)..removeAt(itemIndex);
        }

        // Restore 1 unit of stock.
        if (menuSnap.exists) {
          final menuData = menuSnap.data()!;
          final currentStock =
    (menuData['available_quantity'] as num?)?.toInt() ?? 0;
         tx.update(menuRef, {
  'available_quantity': currentStock + 1,
});
        }

        if (newItems.isEmpty) {
          // Cart is now empty — delete the document.
          tx.delete(cartRef);
          result = null;
          return;
        }

        final subtotal =
            newItems.fold<int>(0, (sum, i) => sum + i.lineTotalPaise);
        final platformFee = 1000;
        final total = subtotal + platformFee;

        tx.update(cartRef, {
          'items': newItems
              .map((i) => {
                    'menu_item_id': i.menuItemId,
                    'vendor_id': i.vendorId,
                    'name': i.name,
                    if (i.imageUrl != null) 'image_url': i.imageUrl,
                    'category': i.category,
                    'unit_price': i.unitPricePaise,
                    'quantity': i.quantity,
                    'is_veg': i.isVeg,
                  })
              .toList(),
          'pricing.subtotal': subtotal,
          'pricing.platform_fee': platformFee,
          'pricing.total': total,
        });

        result = cart.copyWith(
          items: newItems,
          subtotalPaise: subtotal,
          platformFeePaise: platformFee,
          totalPaise: total,
        );
      });

      if (failure != null) return left(failure!);
      return right(result);
    } catch (e) {
      _log.e('[Cart] Error in removeItem', error: e);
      return left(CartFailure.unknown(message: e.toString()));
    }
  }

  // ── clearCart ─────────────────────────────────────────────
  @override
  Future<Either<CartFailure, Unit>> clearCart(String userId) async {
    try {
      final cartRef = _db.collection(_carts).doc(userId);
      final cartSnap = await cartRef.get();
      if (!cartSnap.exists) return right(unit);

      final cart = _fromFirestore(cartSnap);
      final batch = _db.batch();

      // Restore all item quantities back to vendors.
      for (final item in cart.items) {
        final menuRef = _db
            .collection(_vendors)
            .doc(item.vendorId)
            .collection(_menus)
            .doc(item.menuItemId);
        // We use FieldValue.increment to avoid read-then-write race.
        batch.update(menuRef, {
          'available_quantity':
    FieldValue.increment(item.quantity),
        });
      }
      batch.delete(cartRef);
      await batch.commit();

      _log.i('[Cart] Cleared cart for user $userId');
      return right(unit);
    } catch (e) {
      _log.e('[Cart] Error clearing cart', error: e);
      return left(CartFailure.unknown(message: e.toString()));
    }
  }

  // ── lockCart ──────────────────────────────────────────────
  @override
  Future<void> lockCart(String userId) async {
    await _db.collection(_carts).doc(userId).update({
      'expiry.is_locked': true,
    });
  }

  // ── Private: Firestore → CartEntity ──────────────────────
  CartEntity _fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    final pricing = d['pricing'] as Map<String, dynamic>? ?? {};
    final expiry = d['expiry'] as Map<String, dynamic>? ?? {};
    final pickup = d['pickup'] as Map<String, dynamic>? ?? {};
    final rawItems = d['items'] as List<dynamic>? ?? [];

    DateTime fromTs(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();

    final items = rawItems.map((raw) {
      final m = raw as Map<String, dynamic>;
      return CartItemEntity(
        menuItemId: m['menu_item_id'] as String? ?? '',
        vendorId: m['vendor_id'] as String? ?? d['vendor_id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        imageUrl: m['image_url'] as String?,
        category: m['category'] as String? ?? 'General',
        unitPricePaise: (m['unit_price'] as num?)?.toInt() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        isVeg: m['is_veg'] as bool? ?? true,
      );
    }).toList();

    return CartEntity(
      userId: snap.id,
      vendorId: d['vendor_id'] as String? ?? '',
      vendorName: d['vendor_name'] as String? ?? '',
      items: items,
      subtotalPaise: (pricing['subtotal'] as num?)?.toInt() ?? 0,
      platformFeePaise: (pricing['platform_fee'] as num?)?.toInt() ?? 0,
      totalPaise: (pricing['total'] as num?)?.toInt() ?? 0,
      expiresAt: fromTs(expiry['expires_at']),
      isLocked: expiry['is_locked'] as bool? ?? false,
      pickupMode: pickup['mode'] as String? ?? 'in_store',
      createdAt: expiry['created_at'] != null
          ? fromTs(expiry['created_at'])
          : null,
    );
  }
}