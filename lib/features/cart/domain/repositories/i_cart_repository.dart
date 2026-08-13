// ============================================================
// lib/features/cart/domain/repositories/i_cart_repository.dart
//
// FIX: Corrected import path for MenuItemEntity.
// Was:   ../../vendor/  (resolves into cart/vendor/ — wrong)
// Fixed: ../../../vendor/ (resolves to features/vendor/ — correct)
// ============================================================
import 'package:dartz/dartz.dart';

// FIX: Added one extra `../` to escape the cart feature folder.
import '../../../vendor/domain/entities/menu_item_entity.dart';
import '../entities/cart_entity.dart';

abstract class ICartRepository {
  /// Real-time stream of the active cart for this user.
  Stream<CartEntity?> watchCart(String userId);

  /// Atomically: decrement item stock in menus + upsert cart doc.
  Future<Either<CartFailure, CartEntity>> addItem({
    required String userId,
    required String vendorId,
    required String vendorName,
    required MenuItemEntity item,
    required int quantity,
    required int platformFeePercent,
    required int cartExpiryMinutes,
  });

  /// Atomically: restore 1 unit of stock + update cart doc.
  Future<Either<CartFailure, CartEntity?>> removeItem({
    required String userId,
    required String menuItemId,
    required String vendorId,
  });

  /// Delete cart + restore ALL item quantities via batch write.
  Future<Either<CartFailure, Unit>> clearCart(String userId);

  /// Lock the cart when payment is initiated.
  Future<void> lockCart(String userId);
}