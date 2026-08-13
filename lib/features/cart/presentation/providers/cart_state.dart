// ============================================================
// lib/features/cart/presentation/providers/cart_state.dart
//
// Pure cart sealed class hierarchy.
// No @freezed. No auth imports. No generated files.
// Lives in providers/ — no notifiers/ folder.
// ============================================================
import '../../domain/entities/cart_entity.dart';

// ── Base sealed class ─────────────────────────────────────────
sealed class CartState {
  const CartState();
}

/// No active cart document exists in Firestore.
final class CartEmpty extends CartState {
  const CartEmpty();
}

/// A cart mutation (add / remove) is currently in flight.
final class CartLoading extends CartState {
  const CartLoading();
}

/// Active cart with live data.
/// This is the primary state — cart bar, sheet, and item
/// quantity steppers all read from [cart].
final class CartLoaded extends CartState {
  final CartEntity cart;
  const CartLoaded({required this.cart});
}

/// The 5-minute countdown timer fired.
/// CartNotifier has already deleted the Firestore document and
/// batch-restored all item quantities to their menu entries.
final class CartExpired extends CartState {
  const CartExpired();
}

/// A user action (add / remove / clear) failed.
/// [previousCart] is non-null when a cart existed before
/// the failure — the UI uses it to keep rendering the cart
/// while displaying the error snackbar.
final class CartActionError extends CartState {
  final CartFailure failure;
  final CartEntity? previousCart;
  const CartActionError({
    required this.failure,
    this.previousCart,
  });
}