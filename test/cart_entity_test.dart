// Pure Dart unit tests for the cart domain entities.
//
// These tests exercise no Flutter/Firebase dependencies (cart_entity.dart is
// plain Dart with no codegen), so they run on any Dart runtime, including CI.
// They replaced the stale counter widget smoke test that referenced the
// non-existent `MyApp` widget.

import 'package:flutter_test/flutter_test.dart';

import 'package:biteo/features/cart/domain/entities/cart_entity.dart';

void main() {
  group('CartItemEntity', () {
    CartItemEntity item({
      String id = 'item-1',
      String vendorId = 'vendor-1',
      int unitPricePaise = 19900,
      int quantity = 2,
    }) {
      return CartItemEntity(
        menuItemId: id,
        vendorId: vendorId,
        name: 'Paneer Butter Masala',
        category: 'Main Course',
        unitPricePaise: unitPricePaise,
        quantity: quantity,
      );
    }

    test('lineTotalPaise is unitPricePaise times quantity', () {
      expect(item().lineTotalPaise, 19900 * 2);
    });

    test('lineTotalDisplay renders rupees without decimals', () {
      expect(item().lineTotalDisplay, '₹398');
    });

    test('copyWith preserves unchanged fields and updates quantity', () {
      final original = item();
      final updated = original.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.menuItemId, original.menuItemId);
      expect(updated.unitPricePaise, original.unitPricePaise);
    });

    test('equality is based on id, vendor and quantity', () {
      expect(item(), item());
      expect(item().copyWith(quantity: 3), isNot(item()));
    });
  });

  group('CartEntity', () {
    CartItemEntity veg() => CartItemEntity(
          menuItemId: 'veg-1',
          vendorId: 'vendor-1',
          name: 'Veg Thali',
          category: 'Meals',
          unitPricePaise: 12000,
          quantity: 1,
          isVeg: true,
        );

    CartItemEntity chicken() => CartItemEntity(
          menuItemId: 'chk-1',
          vendorId: 'vendor-1',
          name: 'Chicken Curry',
          category: 'Main Course',
          unitPricePaise: 25000,
          quantity: 3,
          isVeg: false,
        );

    CartEntity cart({
      List<CartItemEntity>? items,
      DateTime? expiresAt,
    }) {
      final now = DateTime.now();
      return CartEntity(
        userId: 'user-1',
        vendorId: 'vendor-1',
        vendorName: 'Biteo Kitchen',
        items: items ?? [veg(), chicken()],
        subtotalPaise: 49000,
        platformFeePaise: 199,
        totalPaise: 49199,
        expiresAt: expiresAt ?? now.add(const Duration(minutes: 5)),
      );
    }

    test('totalItemCount sums quantities across items', () {
      expect(cart().totalItemCount, 4);
    });

    test('isExpired is false before expiry and true after', () {
      expect(cart().isExpired, isFalse);
      expect(
        cart(expiresAt: DateTime.now().subtract(const Duration(seconds: 1)))
            .isExpired,
        isTrue,
      );
    });

    test('quantityOf returns 0 when item is absent', () {
      expect(cart().quantityOf('missing'), 0);
    });

    test('copyWith replaces items and keeps remaining fields', () {
      final updated = cart().copyWith(items: [veg()], isLocked: true);
      expect(updated.totalItemCount, 1);
      expect(updated.isLocked, isTrue);
      expect(updated.vendorId, 'vendor-1');
    });
  });

  group('CartFailure', () {
    test('differentVendor exposes a user-facing message', () {
      expect(
        CartFailure.differentVendor().userMessage,
        contains('another restaurant'),
      );
    });

    test('insufficientStock reflects remaining stock', () {
      expect(CartFailure.insufficientStock(available: 0).userMessage,
          contains('sold out'));
      expect(CartFailure.insufficientStock(available: 2).userMessage,
          contains('2'));
    });

    test('cartExpired message explains the auto-return', () {
      expect(CartFailure.cartExpired().userMessage, contains('expired'));
    });

    test('unknown carries an optional message', () {
      expect(CartFailure.unknown().userMessage, contains('try again'));
    });
  });
}
