// ============================================================
// lib/features/cart/domain/entities/cart_entity.dart
//
// FIX: Removed @freezed annotation and all `part` directives.
// Plain Dart immutable classes with manual copyWith.
// No code generation required — compiles immediately.
// ============================================================

// ── Cart Item ─────────────────────────────────────────────────
class CartItemEntity {
  final String menuItemId;
  final String vendorId;
  final String name;
  final String? imageUrl;
  final String category;

  /// Price at the moment the item was added. Immutable snapshot.
  final int unitPricePaise;
  final int quantity;
  final bool isVeg;

  const CartItemEntity({
    required this.menuItemId,
    required this.vendorId,
    required this.name,
    this.imageUrl,
    required this.category,
    required this.unitPricePaise,
    required this.quantity,
    this.isVeg = true,
  });

  // ── Computed ──────────────────────────────────────────────
  int get lineTotalPaise => unitPricePaise * quantity;

  String get unitPriceDisplay =>
      '₹${(unitPricePaise / 100).toStringAsFixed(0)}';

  String get lineTotalDisplay =>
      '₹${(lineTotalPaise / 100).toStringAsFixed(0)}';

  // ── copyWith ──────────────────────────────────────────────
  CartItemEntity copyWith({
    String? menuItemId,
    String? vendorId,
    String? name,
    String? imageUrl,
    String? category,
    int? unitPricePaise,
    int? quantity,
    bool? isVeg,
  }) {
    return CartItemEntity(
      menuItemId: menuItemId ?? this.menuItemId,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      quantity: quantity ?? this.quantity,
      isVeg: isVeg ?? this.isVeg,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItemEntity &&
          menuItemId == other.menuItemId &&
          vendorId == other.vendorId &&
          quantity == other.quantity;

  @override
  int get hashCode =>
      menuItemId.hashCode ^ vendorId.hashCode ^ quantity.hashCode;
}

// ── Cart ──────────────────────────────────────────────────────
class CartEntity {
  final String userId;
  final String vendorId;
  final String vendorName;
  final List<CartItemEntity> items;
  final int subtotalPaise;
  final int platformFeePaise;
  final int totalPaise;

  /// 5-minute lock. Cart auto-clears when this passes.
  final DateTime expiresAt;
  final bool isLocked;
  final String pickupMode;
  final DateTime? createdAt;

  const CartEntity({
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.subtotalPaise,
    required this.platformFeePaise,
    required this.totalPaise,
    required this.expiresAt,
    this.isLocked = false,
    this.pickupMode = 'in_store',
    this.createdAt,
  });

  // ── Computed ──────────────────────────────────────────────
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  Duration get remaining {
    final r = expiresAt.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  String get subtotalDisplay =>
      '₹${(subtotalPaise / 100).toStringAsFixed(0)}';

  String get totalDisplay =>
      '₹${(totalPaise / 100).toStringAsFixed(0)}';

  String get platformFeeDisplay =>
      '₹${(platformFeePaise / 100).toStringAsFixed(0)}';

  int quantityOf(String menuItemId) {
    final matches = items.where((i) => i.menuItemId == menuItemId);
    return matches.isEmpty ? 0 : matches.first.quantity;
  }

  // ── copyWith ──────────────────────────────────────────────
  CartEntity copyWith({
    String? userId,
    String? vendorId,
    String? vendorName,
    List<CartItemEntity>? items,
    int? subtotalPaise,
    int? platformFeePaise,
    int? totalPaise,
    DateTime? expiresAt,
    bool? isLocked,
    String? pickupMode,
    DateTime? createdAt,
  }) {
    return CartEntity(
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      items: items ?? this.items,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      platformFeePaise: platformFeePaise ?? this.platformFeePaise,
      totalPaise: totalPaise ?? this.totalPaise,
      expiresAt: expiresAt ?? this.expiresAt,
      isLocked: isLocked ?? this.isLocked,
      pickupMode: pickupMode ?? this.pickupMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ── Cart Failure ──────────────────────────────────────────────
// FIX: Replaced @freezed with abstract class + factory constructors.
// Same API — CartFailure.differentVendor(), .insufficientStock(), etc.
// Every failure variant exposes `userMessage` for the UI.
abstract class CartFailure {
  const CartFailure();

  String get userMessage;

  const factory CartFailure.differentVendor() = _DifferentVendor;
  const factory CartFailure.itemNotFound() = _ItemNotFound;
  const factory CartFailure.insufficientStock({required int available}) =
      _InsufficientStock;
  const factory CartFailure.cartExpired() = _CartExpired;
  const factory CartFailure.cartLocked() = _CartLocked;
  const factory CartFailure.networkError() = _NetworkError;
  const factory CartFailure.unknown({String? message}) = _Unknown;
}

final class _DifferentVendor extends CartFailure {
  const _DifferentVendor();
  @override
  String get userMessage =>
      'Your cart has items from another restaurant. Clear it to add from here.';
}

final class _ItemNotFound extends CartFailure {
  const _ItemNotFound();
  @override
  String get userMessage => 'This item is no longer available.';
}

final class _InsufficientStock extends CartFailure {
  final int available;
  const _InsufficientStock({required this.available});
  @override
  String get userMessage => available == 0
      ? 'This item just sold out!'
      : 'Only $available left in stock.';
}

final class _CartExpired extends CartFailure {
  const _CartExpired();
  @override
  String get userMessage =>
      'Your cart expired. Items have been returned to the restaurant.';
}

final class _CartLocked extends CartFailure {
  const _CartLocked();
  @override
  String get userMessage => 'Your cart is being processed. Please wait.';
}

final class _NetworkError extends CartFailure {
  const _NetworkError();
  @override
  String get userMessage => 'Network error. Please check your connection.';
}

final class _Unknown extends CartFailure {
  final String? message;
  const _Unknown({this.message});
  @override
  String get userMessage => 'Something went wrong. Please try again.';
}