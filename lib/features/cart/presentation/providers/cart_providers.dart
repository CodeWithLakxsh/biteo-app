// ============================================================
// lib/features/cart/presentation/providers/cart_providers.dart
//
// CTO FIX: Fixed the import paths. Since everything is now safely
// inside the 'providers' folder, we use direct sibling imports.
// Your logic remains 100% untouched.
// ============================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FIX: Direct imports since they are in the same 'providers' folder now
import 'cart_notifier.dart';
import 'cart_state.dart';

/// Primary cart provider — watched by all commerce UI.
final cartNotifierProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Live countdown stream: emits remaining Duration every second.
/// Used by the floating cart bar timer.
final cartCountdownProvider = StreamProvider.autoDispose<Duration>((ref) {
  final cartState = ref.watch(cartNotifierProvider);

  // FIX: Use `is CartLoaded` instead of .mapOrNull(loaded: ...)
  if (cartState is! CartLoaded) return Stream.value(Duration.zero);
  final expiresAt = cartState.cart.expiresAt;

  return Stream.periodic(const Duration(seconds: 1), (_) {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  });
});

/// Convenience: total item count in the current cart.
final cartItemCountProvider = Provider.autoDispose<int>((ref) {
  final cartState = ref.watch(cartNotifierProvider);
  // FIX: Use `is CartLoaded` instead of .maybeWhen(loaded: ...)
  if (cartState is CartLoaded) return cartState.cart.totalItemCount;
  return 0;
});