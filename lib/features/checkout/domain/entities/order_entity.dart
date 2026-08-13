// ============================================================
// lib/features/checkout/domain/entities/order_entity.dart
// FINAL CORRECT VERSION (STATUS + BITEO POINTS FIXED)
// ============================================================

class OrderItemEntity {
  final String menuItemId;
  final String name;
  final String? imageUrl;
  final int unitPricePaise;
  final int quantity;
  final bool isVeg;

  const OrderItemEntity({
    required this.menuItemId,
    required this.name,
    this.imageUrl,
    required this.unitPricePaise,
    required this.quantity,
    this.isVeg = true,
  });

  int get lineTotalPaise =>
      unitPricePaise * quantity;

  String get unitPriceDisplay =>
      '₹${(unitPricePaise / 100).toStringAsFixed(0)}';

  String get lineTotalDisplay =>
      '₹${(lineTotalPaise / 100).toStringAsFixed(0)}';

  factory OrderItemEntity.fromCartItem(
    Map<String, dynamic> raw,
  ) {
    return OrderItemEntity(
      menuItemId:
          raw['menu_item_id']
                  as String? ??
              '',

      name:
          raw['name']
                  as String? ??
              '',

      imageUrl:
          raw['image_url']
              as String?,

      unitPricePaise:
          (raw['unit_price']
                      as num?)
                  ?.toInt() ??
              0,

      quantity:
          (raw['quantity']
                      as num?)
                  ?.toInt() ??
              1,

      isVeg:
          raw['is_veg']
                  as bool? ??
              true,
    );
  }
}

// ============================================================
// ORDER ENTITY
// ============================================================

class OrderEntity {

  // ─────────────────────────────────────────────────────────
  // BASIC
  // ─────────────────────────────────────────────────────────

  final String orderId;
  final String userId;
  final String vendorId;
  final String vendorName;

  // ─────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────

  final List<OrderItemEntity> items;

  // ─────────────────────────────────────────────────────────
  // PRICING
  // ─────────────────────────────────────────────────────────

  final int subtotalPaise;
  final int platformFeePaise;

  /// 🔥 NEW
  final int biteoPointsUsed;

  /// 🔥 NEW
  final int biteoPointsDiscountPaise;

  /// 🔥 NEW
  final int biteoPointsEarned;

  final int totalPaise;

  // ─────────────────────────────────────────────────────────
  // PAYMENT
  // ─────────────────────────────────────────────────────────

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String paymentStatus;

  // ─────────────────────────────────────────────────────────
  // ORDER STATE
  // ─────────────────────────────────────────────────────────

  final String status;

  final String otpCode;
  final String pickupMode;

  final int estimatedReadyMinutes;

  final DateTime? createdAt;

  const OrderEntity({

    // ── Basic ─────────────────────────
    required this.orderId,
    required this.userId,
    required this.vendorId,
    required this.vendorName,

    // ── Items ─────────────────────────
    required this.items,

    // ── Pricing ───────────────────────
    required this.subtotalPaise,
    required this.platformFeePaise,

    // 🔥 NEW
    this.biteoPointsUsed = 0,

    // 🔥 NEW
    this.biteoPointsDiscountPaise = 0,

    // 🔥 NEW
    this.biteoPointsEarned = 0,

    required this.totalPaise,

    // ── Payment ───────────────────────
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.paymentStatus,

    // ── Status ────────────────────────
    required this.status,

    required this.otpCode,
    required this.pickupMode,

    this.estimatedReadyMinutes = 20,
    this.createdAt,
  });

  // =========================================================
  // DISPLAY HELPERS
  // =========================================================

  String get subtotalDisplay =>
      '₹${(subtotalPaise / 100).toStringAsFixed(0)}';

  String get platformFeeDisplay =>
      '₹${(platformFeePaise / 100).toStringAsFixed(0)}';

  /// 🔥 NEW
  String get biteoDiscountDisplay =>
      '-₹${(biteoPointsDiscountPaise / 100).toStringAsFixed(0)}';

  /// 🔥 NEW
  String get biteoEarnedDisplay =>
      '$biteoPointsEarned Points';

  String get totalDisplay =>
      '₹${(totalPaise / 100).toStringAsFixed(0)}';

  int get totalItemCount =>
      items.fold(
        0,
        (sum, item) =>
            sum + item.quantity,
      );

  // =========================================================
  // STATUS DISPLAY
  // =========================================================

  String get statusDisplay {

    switch (status) {

      case 'pending':
        return 'Waiting for vendor ⏳';

      case 'accepted':
        return 'Order Accepted ✅';

      case 'preparing':
        return 'Being Prepared 🍳';

      case 'ready':
        return 'Ready for Pickup 📦';

      case 'completed':
        return 'Completed 🎉';

      case 'rejected':
        return 'Rejected ❌';

      default:
        return 'Processing';
    }
  }

  // =========================================================
  // ORDER ID DISPLAY
  // =========================================================

  String get shortOrderId =>
      orderId.length > 8
          ? '#${orderId.substring(0, 8).toUpperCase()}'
          : '#$orderId';

  // =========================================================
  // 🔥 NEW HELPERS
  // =========================================================

  /// 5% loyalty calculation helper
  static int calculateEarnedPoints(
    int amountPaise,
  ) {
    final rupees =
        amountPaise ~/ 100;

    return (rupees * 0.05).floor();
  }

  /// Convert points → paise
  static int pointsToPaise(
    int points,
  ) {
    return points * 100;
  }

  /// Convert paise → points
  static int paiseToPoints(
    int paise,
  ) {
    return paise ~/ 100;
  }

  bool get hasUsedPoints =>
      biteoPointsUsed > 0;

  bool get hasEarnedPoints =>
      biteoPointsEarned > 0;
}