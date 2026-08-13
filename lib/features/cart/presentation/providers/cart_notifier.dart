// ============================================================
// lib/features/cart/presentation/providers/cart_notifier.dart
// ============================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/i_cart_repository.dart';
import '../../../vendor/domain/entities/menu_item_entity.dart';
import 'cart_state.dart';

class CartNotifier extends Notifier<CartState> {
  Timer? _expiryTimer;

  StreamSubscription<CartEntity?>? _cartSub;

  final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
    ),
  );

  ICartRepository get _repo =>
      ref.read(_cartRepositoryProvider);

  String? get _userId {
    final authState =
        ref.read(authNotifierProvider);

    if (authState is AuthAuthenticated) {
      print(
        "✅ USER LOGGED IN: ${authState.user.uid}",
      );

      return authState.user.uid;
    }

    print("❌ USER NOT LOGGED IN");

    return null;
  }

  @override
  CartState build() {
    ref.onDispose(() {
      _expiryTimer?.cancel();
      _cartSub?.cancel();
    });

    final userId = _userId;

    if (userId == null) {
      return const CartEmpty();
    }

    _cartSub =
        _repo.watchCart(userId).listen(
      (cart) {
        print(
          "🛒 CART STREAM UPDATE: $cart",
        );

        if (cart == null) {
          _expiryTimer?.cancel();

          state = const CartEmpty();

          return;
        }

        if (cart.isExpired) {
          _triggerExpiry();

          return;
        }

        state = CartLoaded(
          cart: cart,
        );

        _scheduleExpiryTimer(
          cart.expiresAt,
        );
      },
      onError: (e) {
        _log.e(
          '[CartNotifier] Stream error',
          error: e,
        );
      },
    );

    return const CartEmpty();
  }

  // ── Add Item ──────────────────────────────────────────────

  Future<void> addItem({
    required String vendorId,
    required String vendorName,
    required MenuItemEntity item,
    int quantity = 1,
  }) async {
    print("🛒 ADD ITEM CALLED");

    print("vendorId: $vendorId");

    print("vendorName: $vendorName");

    print("item: ${item.name}");

    final userId = _userId;

    if (userId == null) {
      print("❌ ADD FAILED: USER NULL");

      return;
    }

    final result =
        await _repo.addItem(
      userId: userId,
      vendorId: vendorId,
      vendorName: vendorName,
      item: item,
      quantity: quantity,
      platformFeePercent: 0,
      cartExpiryMinutes: 10,
    );

    result.fold(
      (failure) {
        print(
          "❌ ADD FAILED: $failure",
        );

        final previous =
            state is CartLoaded
                ? (state as CartLoaded).cart
                : null;

        state = CartActionError(
          failure: failure,
          previousCart: previous,
        );

        if (previous != null) {
          Future.delayed(
            const Duration(seconds: 3),
            () {
              if (state
                  is CartActionError) {
                state = CartLoaded(
                  cart: previous,
                );
              }
            },
          );
        }
      },
      (cart) {
        print(
          "✅ ITEM ADDED SUCCESS",
        );

        state = CartLoaded(
          cart: cart,
        );

        _scheduleExpiryTimer(
          cart.expiresAt,
        );

        _log.i(
          '[CartNotifier] Added: ${item.name}',
        );
      },
    );
  }

  // ── Increase Quantity ─────────────────────────────────────

  Future<void> increaseQuantity(
    String menuItemId,
  ) async {
    if (state is! CartLoaded) {
      return;
    }

    final cart =
        (state as CartLoaded).cart;

    final existingItem =
        cart.items.firstWhere(
      (e) =>
          e.menuItemId ==
          menuItemId,
    );

    await addItem(
      vendorId: existingItem.vendorId,
      vendorName: cart.vendorName,
      quantity: 1,
    item: MenuItemEntity(
  id: existingItem.menuItemId,
  vendorId: existingItem.vendorId,
  name: existingItem.name,

  description: null,

  imageUrl: existingItem.imageUrl,

  category: existingItem.category,

  originalPricePaise:
      existingItem.unitPricePaise,

  discountedPricePaise:
      existingItem.unitPricePaise,

  discountPercent: 0,

  availableQuantity: 999,

  maxPerOrder: 10,

  isVeg: existingItem.isVeg,

  isVegan: false,

  allergens: const [],

  isAvailable: true,

  availableFrom: null,

  availableUntil: null,
),
    );
  }

  // ── Decrease Quantity ─────────────────────────────────────

  Future<void> decreaseQuantity(
    String menuItemId,
  ) async {
    if (state is! CartLoaded) {
      return;
    }

    final cart =
        (state as CartLoaded).cart;

    final existingItem =
        cart.items.firstWhere(
      (e) =>
          e.menuItemId ==
          menuItemId,
    );

    // REMOVE COMPLETELY
    if (existingItem.quantity <= 1) {
      await removeItem(
        menuItemId: menuItemId,
        vendorId:
            existingItem.vendorId,
      );

      return;
    }

    final updatedItems =
        cart.items.map((item) {
      if (item.menuItemId ==
          menuItemId) {
        return item.copyWith(
          quantity:
              item.quantity - 1,
        );
      }

      return item;
    }).toList();

    final updatedSubtotal =
        updatedItems.fold<int>(
      0,
      (sum, item) =>
          sum + item.lineTotalPaise,
    );

final updatedPlatformFee = 1000;

    final updatedTotal =
        updatedSubtotal +
            updatedPlatformFee;

    final updatedCart =
        cart.copyWith(
      items: updatedItems,
      subtotalPaise:
          updatedSubtotal,
      totalPaise:
          updatedTotal,
    );

    state = CartLoaded(
      cart: updatedCart,
    );
  }

  // ── OLD METHOD ALIASES ────────────────────────────────────

  Future<void> incrementQuantity(
    String menuItemId,
  ) async {
    await increaseQuantity(
      menuItemId,
    );
  }

  Future<void> decrementQuantity(
    String menuItemId,
  ) async {
    await decreaseQuantity(
      menuItemId,
    );
  }

  // ── Remove Item ───────────────────────────────────────────

  Future<void> removeItem({
    required String menuItemId,
    required String vendorId,
  }) async {
    final userId = _userId;

    if (userId == null) return;

    final result =
        await _repo.removeItem(
      userId: userId,
      menuItemId: menuItemId,
      vendorId: vendorId,
    );

    result.fold(
      (failure) {
        final previous =
            state is CartLoaded
                ? (state as CartLoaded).cart
                : null;

        state = CartActionError(
          failure: failure,
          previousCart: previous,
        );
      },
      (cart) {
        if (cart == null) {
          _expiryTimer?.cancel();

          state = const CartEmpty();
        } else {
          state = CartLoaded(
            cart: cart,
          );
        }
      },
    );
  }

  // ── Clear Cart ────────────────────────────────────────────

  Future<void> clearCart() async {
    final userId = _userId;

    if (userId == null) return;

    _expiryTimer?.cancel();

    await _repo.clearCart(userId);

    state = const CartEmpty();
  }

  // ── Dismiss Error ─────────────────────────────────────────

  void dismissError() {
    if (state is CartActionError) {
      final previous =
          (state as CartActionError)
              .previousCart;

      state = previous != null
          ? CartLoaded(
              cart: previous,
            )
          : const CartEmpty();
    }
  }

  // ── Expiry Timer ──────────────────────────────────────────

  void _scheduleExpiryTimer(
    DateTime expiresAt,
  ) {
    _expiryTimer?.cancel();

    final remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining ==
            Duration.zero) {
      _triggerExpiry();

      return;
    }

    _expiryTimer = Timer(
      remaining,
      _triggerExpiry,
    );
  }

  // ── Trigger Expiry ────────────────────────────────────────

  void _triggerExpiry() {
    _expiryTimer?.cancel();

    state = const CartExpired();

    final userId = _userId;

    if (userId != null) {
      _repo.clearCart(userId);
    }

    Future.delayed(
      const Duration(seconds: 4),
      () {
        if (state is CartExpired) {
          state = const CartEmpty();
        }
      },
    );
  }
}

final _cartRepositoryProvider =
    Provider<ICartRepository>(
  (_) => CartRepositoryImpl(),
);